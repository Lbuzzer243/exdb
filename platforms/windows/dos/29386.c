# Exploit Title: Base Texture Exploit
# Date: 11/1/2013
# Exploit Author: XTAM4
# Vendor Homepage: www.directx.com
# Software Link: http://www.microsoft.com/en-pk/download/details.aspx?id=17431
# Version : DIRECT X 9, 10 and 1
# Tested on: LIGHT OS and Windows 7
# CVE : None


using System;
using System.ComponentModel;
using Root;
using Microsoft.DirectX;
using Microsoft.DirectX.PrivateImplementationDetails;

namespace Microsoft.DirectX.Direct3D
{

    public abstract class BaseTexture : Microsoft.DirectX.Direct3D.Resource
    {

        private Microsoft.DirectX.Direct3D.Device m_Device;
        internal unsafe Microsoft.DirectX.PrivateImplementationDetails.IDirect3DBaseTexture9* m_lpUM;
        private Microsoft.DirectX.Direct3D.Pool m_Pool;

        public unsafe Microsoft.DirectX.Direct3D.TextureFilter AutoGenerateFilterType
        {
            get
            {
                return (Microsoft.DirectX.Direct3D.TextureFilter)(m_lpUM + 60);
            }
            set
            {
                int i = m_lpUM + 56;
                if (i < 0)
                {
                    if (!Microsoft.DirectX.DirectXException.IsExceptionIgnored)
                    {
                        System.Exception exception = Microsoft.DirectX.Direct3D.GraphicsException.GetExceptionFromResultInternal(i);
                        Microsoft.DirectX.DirectXException directXException = exception as Microsoft.DirectX.DirectXException;
                        if (directXException != null)
                        {
                            directXException.ErrorCode = i;
                            throw directXException;
                        }
                        throw exception;
                    }
                    Root.<Module>.SetLastError(i);
                }
            }
        }

        public unsafe int LevelCount
        {
            get
            {
                return m_lpUM + 52;
            }
        }

        public unsafe int LevelOfDetail
        {
            get
            {
                return m_lpUM + 48;
            }
            set
            {
            }
        }

        [System.CLSCompliant(false)]
        public unsafe new Microsoft.DirectX.PrivateImplementationDetails.IDirect3DBaseTexture9* UnmanagedComPointer
        {
            get
            {
                return m_lpUM;
            }
        }

        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.U1)]
        public static unsafe bool operator ==(Microsoft.DirectX.Direct3D.BaseTexture left, Microsoft.DirectX.Direct3D.BaseTexture right)
        {
            if (left == null)
            {
                if (right != null)
                    return false;
                return true;
            }
            if (right != null)
                return left.m_lpUM == right.m_lpUM;
            return false;
        }

        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.U1)]
        public static bool operator !=(Microsoft.DirectX.Direct3D.BaseTexture left, Microsoft.DirectX.Direct3D.BaseTexture right)
        {
            return left != right;
        }

        [System.CLSCompliant(false)]
        public unsafe BaseTexture(Microsoft.DirectX.PrivateImplementationDetails.IDirect3DBaseTexture9* pInterop) : base((Microsoft.DirectX.PrivateImplementationDetails.IDirect3DResource9)0)
        {
            if (pInterop != null)
            {
                m_lpUM = pInterop;
                base.SetObject(pInterop);
            }
        }

        public unsafe BaseTexture(System.IntPtr unmanagedObject) : base((Microsoft.DirectX.PrivateImplementationDetails.IDirect3DResource9)0)
        {
            Microsoft.DirectX.PrivateImplementationDetails.IDirect3DBaseTexture9* idirect3DBaseTexture9Ptr = unmanagedObject.ToPointer();
            m_lpUM = idirect3DBaseTexture9Ptr;
            base.SetObject(idirect3DBaseTexture9Ptr);
        }

        public void GenerateMipSubLevels()
        {
        }

        [System.ComponentModel.EditorBrowsable(System.ComponentModel.EditorBrowsableState.Never)]
        public new unsafe System.IntPtr GetObjectByValue(int uniqueKey)
        {
            System.IntPtr intPtr1, intPtr2;

            if (uniqueKey == -759872593)
            {
                intPtr1 = new System.IntPtr();
                intPtr1 = new System.IntPtr(m_lpUM);
                return intPtr1;
            }
            throw new System.ArgumentException();
        }

        public int SetLevelOfDetail(int lodNew)
        {
            // trial
            return 0;
        }

        [System.CLSCompliant(false)]
        public unsafe void UpdateUnmanagedPointer(Microsoft.DirectX.PrivateImplementationDetails.IDirect3DBaseTexture9* pInterface)
        {
            // trial
        }

        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.U1)]
        public override bool Equals(object compare)
        {
            // trial
            return false;
        }

        public override int GetHashCode()
        {
            return ToString().GetHashCode();
        }

        protected internal virtual unsafe void SetObject(Microsoft.DirectX.PrivateImplementationDetails.IDirect3DBaseTexture9* lp)
        {
            // trial
        }

    } // class BaseTexture

}
