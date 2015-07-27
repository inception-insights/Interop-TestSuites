//-----------------------------------------------------------------------
// Copyright (c) 2014 Microsoft Corporation. All rights reserved.
// Use of this sample source code is subject to the terms of the Microsoft license 
// agreement under which you licensed this sample source code and is provided AS-IS.
// If you did not accept the terms of the license agreement, you are not authorized 
// to use this sample source code. For the terms of the license, please see the 
// license agreement between you and Microsoft.
//-----------------------------------------------------------------------

namespace Microsoft.Protocols.TestSuites.MS_OXCFXICS
{
    /// <summary>
    /// The errorInfo element provides for out-of-band error reporting and recovery. 
    /// errorInfo  = FXErrorInfo propList
    /// </summary>
    public class ErrorInfo : SyntacticalBase
    {
        /// <summary>
        /// The start marker of errorInfo.
        /// </summary>
        public const Markers StartMarker = Markers.PidTagFXErrorInfo;

        /// <summary>
        /// A propList value.
        /// </summary>
        private PropList propList;

        /// <summary>
        /// Initializes a new instance of the ErrorInfo class.
        /// </summary>
        /// <param name="stream">A FastTransferStream.</param>
        public ErrorInfo(FastTransferStream stream)
            : base(stream)
        {
        }

        /// <summary>
        /// Gets the propList.
        /// </summary>
        public PropList PropList
        {
            get
            {
                return this.propList;
            }
        }

        /// <summary>
        /// Verify that a stream's current position contains a serialized errorInfo.
        /// </summary>
        /// <param name="stream">A FastTransferStream.</param>
        /// <returns>If the stream's current position contains 
        /// a serialized errorInfo, return true, else false.</returns>
        public static bool Verify(FastTransferStream stream)
        {
            return stream.VerifyMarker(StartMarker);
        }

        /// <summary>
        /// Deserialize fields from a FastTransferStream.
        /// </summary>
        /// <param name="stream">A FastTransferStream.</param>
        public override void Deserialize(FastTransferStream stream)
        {
            byte[] buffer = new byte[PidLength];
            int len = stream.Read(buffer, 0, PidLength);
            if (len == SyntacticalBase.PidLength)
            {
                this.propList = new PropList(stream);
                return;
            }

            AdapterHelper.Site.Assert.Fail("The stream cannot be deserialized successfully.");
        }
    }
}