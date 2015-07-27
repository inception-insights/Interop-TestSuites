//-----------------------------------------------------------------------
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
// Use of this sample source code is subject to the terms of the Microsoft license 
// agreement under which you licensed this sample source code and is provided AS-IS.
// If you did not accept the terms of the license agreement, you are not authorized 
// to use this sample source code. For the terms of the license, please see the 
// license agreement between you and Microsoft.
//-----------------------------------------------------------------------

namespace Microsoft.Protocols.TestSuites.Common
{
    using System;
    using System.IO;
    using System.Xml;

    /// <summary>
    /// A class represents a Xml Writer XmlWriterInjector which inherits from "XmlWriter".
    /// Use this class instead of XmlWriter to get the request data from request stream during the processing of the proxy class generated by WSDL.exe.
    /// </summary>
    public class XmlWriterInjector : XmlWriter
    {   
        /// <summary>
        /// An XmlWriter instance.
        /// </summary>
        private XmlWriter originalXmlWriter;

        /// <summary>
        ///  An XmlTextWriter instance.
        /// </summary>
        private XmlTextWriter injectorXmlTextWriter;

        /// <summary>
        /// A StringWriter instance.
        /// </summary>
        private StringWriter stringWriterInstance;

        /// <summary>
        /// Initializes a new instance of the XmlWriterInjector class.
        /// </summary>
        /// <param name="implementation">A parameter instance represents an XmlWriter type implementation.</param>
        public XmlWriterInjector(XmlWriter implementation)
        {
            this.originalXmlWriter = implementation;
            this.stringWriterInstance = new StringWriter();
            this.injectorXmlTextWriter = new XmlTextWriter(this.stringWriterInstance);
            this.injectorXmlTextWriter.Formatting = Formatting.Indented;
        }

        /// <summary>
        /// Gets the xml string which is written to request stream.
        /// </summary>
        public string Xml 
        {   
            get 
            { 
                return this.stringWriterInstance == null ? null : this.stringWriterInstance.ToString(); 
            } 
        }

        /// <summary>
        /// A method used to override the method "WriteState" of XmlWriter.
        /// </summary>
        public override WriteState WriteState
        {
            get
            {
                return this.originalXmlWriter.WriteState;
            }
        }

        /// <summary>
        /// Gets the current xml:lang scope.
        /// </summary>
        public override string XmlLang
        {
            get
            {
                return this.originalXmlWriter.XmlLang;
            }
        }

        /// <summary>
        /// Gets an System.Xml.XmlSpace representing the current xml:space scope.
        /// None: This is the default value if no xml:space scope exists.
        /// Default: This value is meaning the current scope is xml:space="default". 
        /// Preserve: This value is meaning the current scope is xml:space="preserve".  
        /// </summary>
        public override XmlSpace XmlSpace
        {
            get
            {
                return this.originalXmlWriter.XmlSpace;
            }
        }

        /// <summary>
        /// A method used to override the method "Flush".
        /// It flushes whatever is in the buffer to the underlying streams and also flushes the underlying stream.
        /// </summary>
        public override void Flush()
        {
            this.originalXmlWriter.Flush();
            this.injectorXmlTextWriter.Flush();
            this.stringWriterInstance.Flush();
        }

        /// <summary>
        ///  A method used to override the method "Close".
        ///  It closes this stream and the underlying stream.
        /// </summary>
        public override void Close() 
        { 
            this.originalXmlWriter.Close(); 
            this.injectorXmlTextWriter.Close(); 
        }
        
        /// <summary>
        /// A method used to override the method "LookupPrefix".
        /// It returns the closest prefix defined in the current namespace scope for the namespace URI.
        /// </summary>
        /// <param name="ns">A method represents the namespace URI whose prefix you want to find.</param>
        /// <returns> A return value represents the matching prefix or null if no matching namespace URI is found in the current scope.</returns>
        public override string LookupPrefix(string ns) 
        { 
            return this.originalXmlWriter.LookupPrefix(ns); 
        }
       
        /// <summary>
        /// A method used to override the method "WriteBase64" of XmlWriter.
        /// </summary>
        /// <param name="buffer">A parameter represents Byte array to encode.</param>
        /// <param name="index">A parameter represents the position in the buffer indicating the start of the bytes to write.</param>
        /// <param name="count">A parameter represents the number of bytes to write.</param>
        public override void WriteBase64(byte[] buffer, int index, int count) 
        { 
            this.originalXmlWriter.WriteBase64(buffer, index, count); 
            this.injectorXmlTextWriter.WriteBase64(buffer, index, count); 
        }
        
        /// <summary>
        ///  A method used to override the method "WriteCData" of XmlWriter.
        /// </summary>
        /// <param name="text">A parameter represents the text to place inside the CDATA block.</param>
        public override void WriteCData(string text) 
        { 
            this.originalXmlWriter.WriteCData(text); 
            this.injectorXmlTextWriter.WriteCData(text); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteCharEntity" of XmlWriter.
        /// </summary>
        /// <param name="ch">A parameter represents the Unicode character for which to generate a character entity.</param>
        public override void WriteCharEntity(char ch) 
        { 
            this.originalXmlWriter.WriteCharEntity(ch); 
            this.injectorXmlTextWriter.WriteCharEntity(ch); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteChars" of XmlWriter.
        /// </summary>
        /// <param name="buffer">A parameter represents the character array containing the text to write.</param>
        /// <param name="index">A parameter represents the position in the buffer indicating the start of the text to write.</param>
        /// <param name="count">A parameter represents the number of characters to write.</param>
        public override void WriteChars(char[] buffer, int index, int count) 
        {
            this.originalXmlWriter.WriteChars(buffer, index, count); 
            this.injectorXmlTextWriter.WriteChars(buffer, index, count); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteComment" of XmlWriter.
        /// </summary>
        /// <param name="text">A parameter represents the text to place inside the comment.</param>
        public override void WriteComment(string text) 
        { 
            this.originalXmlWriter.WriteComment(text); 
            this.injectorXmlTextWriter.WriteComment(text); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteDocType" of XmlWriter.
        /// </summary>
        /// <param name="name">A parameter represents the name of the DOCTYPE. This must be non-empty.</param>
        /// <param name="pubid">A parameter represents that if non-null it also writes PUBLIC "pubid" "sysid" where pubid and sysid are replaced with the value of the given arguments.</param>
        /// <param name="sysid">A parameter represents that if pubid is null and sysid is non-null it writes SYSTEM "sysid" where sysid is replaced with the value of this argument.</param>
        /// <param name="subset">A parameter represents that if non-null it writes [subset] where subset is replaced with the value of this argument.</param>
        public override void WriteDocType(string name, string pubid, string sysid, string subset) 
        { 
            this.originalXmlWriter.WriteDocType(name, pubid, sysid, subset); 
            this.injectorXmlTextWriter.WriteDocType(name, pubid, sysid, subset); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteEndAttribute" of XmlWriter.
        /// </summary>
        public override void WriteEndAttribute() 
        { 
            this.originalXmlWriter.WriteEndAttribute(); 
            this.injectorXmlTextWriter.WriteEndAttribute(); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteEndDocument" of XmlWriter.
        /// </summary>
        public override void WriteEndDocument() 
        { 
            this.originalXmlWriter.WriteEndDocument(); 
            this.injectorXmlTextWriter.WriteEndDocument(); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteEndElement" of XmlWriter.
        /// </summary>
        public override void WriteEndElement()
        { 
            this.originalXmlWriter.WriteEndElement();
            this.injectorXmlTextWriter.WriteEndElement();
        }
        
        /// <summary>
        ///  A method used to override the method "WriteEntityRef" of XmlWriter.
        /// </summary>
        /// <param name="name">A parameter represents the name of the entity reference.</param>
        public override void WriteEntityRef(string name) 
        { 
            this.originalXmlWriter.WriteEntityRef(name); 
            this.injectorXmlTextWriter.WriteEntityRef(name);
        }
        
        /// <summary>
        /// A method used to override the method "WriteFullEndElement" of XmlWriter.
        /// </summary>
        public override void WriteFullEndElement()
        { 
            this.originalXmlWriter.WriteFullEndElement();
            this.injectorXmlTextWriter.WriteFullEndElement(); 
        }
       
        /// <summary>
        /// A method used to override the method "WriteProcessingInstruction" of XmlWriter.
        /// </summary>
        /// <param name="name">A parameter represents the name of the processing instruction.</param>
        /// <param name="text">A parameter represents the text to include in the processing instruction.</param>
        public override void WriteProcessingInstruction(string name, string text)
        {
            this.originalXmlWriter.WriteProcessingInstruction(name, text);
            this.injectorXmlTextWriter.WriteProcessingInstruction(name, text); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteRaw" of XmlWriter.
        /// </summary>
        /// <param name="data">A parameter represents the string containing the text to write.</param>
        public override void WriteRaw(string data)
        {
            this.originalXmlWriter.WriteRaw(data); 
            this.injectorXmlTextWriter.WriteRaw(data); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteRaw" of XmlWriter.
        /// </summary>
        /// <param name="buffer">A parameter represents character array containing the text to write.</param>
        /// <param name="index">A parameter represents the position within the buffer indicating the start of the text to write.</param>
        /// <param name="count">A parameter represents the number of characters to write.</param>
        public override void WriteRaw(char[] buffer, int index, int count)
        {
            this.originalXmlWriter.WriteRaw(buffer, index, count);
            this.injectorXmlTextWriter.WriteRaw(buffer, index, count); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteStartAttribute" of XmlWriter.
        /// </summary>
        /// <param name="prefix">A parameter represents the namespace prefix of the attribute.</param>
        /// <param name="localName">A parameter represents the local name of the attribute.</param>
        /// <param name="ns">A parameter represents the namespace URI for the attribute.</param>
        public override void WriteStartAttribute(string prefix, string localName, string ns)
        {
            this.originalXmlWriter.WriteStartAttribute(prefix, localName, ns);
            this.injectorXmlTextWriter.WriteStartAttribute(prefix, localName, ns); 
        }
       
        /// <summary>
        /// A method used to override the method "WriteStartDocument" of XmlWriter.
        /// </summary>
        /// <param name="standalone">A parameter represents that if true, it writes "standalone=yes"; if false, it writes "standalone=no".</param>
        public override void WriteStartDocument(bool standalone) 
        { 
            this.originalXmlWriter.WriteStartDocument(standalone);
            this.injectorXmlTextWriter.WriteStartDocument(standalone); 
        }
        
        /// <summary>
        /// A method used to override the method "WriteStartDocument" of XmlWriter.
        /// </summary>
        public override void WriteStartDocument()
        {
            this.originalXmlWriter.WriteStartDocument();
            this.injectorXmlTextWriter.WriteStartDocument();
        }
        
        /// <summary>
        /// A method used to override the method "WriteStartElement" of XmlWriter.
        /// </summary>
        /// <param name="prefix">A parameter represents the namespace prefix of the element.</param>
        /// <param name="localName">A parameter represents the local name of the element.</param>
        /// <param name="ns">A parameter represents the namespace URI to associate with the element.</param>
        public override void WriteStartElement(string prefix, string localName, string ns) 
        {
            this.originalXmlWriter.WriteStartElement(prefix, localName, ns); 
            this.injectorXmlTextWriter.WriteStartElement(prefix, localName, ns);
        }
                
        /// <summary>
        /// A method used to override the method "WriteString" of XmlWriter.
        /// </summary>
        /// <param name="text">A parameter represents the text to write.</param>
        public override void WriteString(string text) 
        { 
            this.originalXmlWriter.WriteString(text);
            this.injectorXmlTextWriter.WriteString(text);
        }
        
        /// <summary>
        /// A method used to override the method "WriteSurrogateCharEntity" of XmlWriter.
        /// </summary>
        /// <param name="lowChar">A parameter represents the low surrogate. This must be a value between 0xDC00 and 0xDFFF.</param>
        /// <param name="highChar">A parameter represents the high surrogate. This must be a value between 0xD800 and 0xDBFF.</param>
        public override void WriteSurrogateCharEntity(char lowChar, char highChar) 
        {
            this.originalXmlWriter.WriteSurrogateCharEntity(lowChar, highChar); 
            this.injectorXmlTextWriter.WriteSurrogateCharEntity(lowChar, highChar);
        }
        
        /// <summary>
        /// A method used to override the method "WriteWhitespace" of XmlWriter.
        /// </summary>
        /// <param name="ws">A parameter represents the string of white space characters.</param>
        public override void WriteWhitespace(string ws)
        { 
            this.originalXmlWriter.WriteWhitespace(ws);
            this.injectorXmlTextWriter.WriteWhitespace(ws);
        }

        /// <summary>
        /// A method used to write out the specified name, ensuring it is a valid name according to the W3C XML 1.0.
        /// </summary>
        /// <param name="name">A parameter represents the name to write.</param>
        public override void WriteName(string name)
        {
            this.originalXmlWriter.WriteName(name);
            this.injectorXmlTextWriter.WriteName(name);
        }

        /// <summary>
        /// A method used to encode the specified binary bytes as BinHex and writes out the resulting text.
        /// </summary>
        /// <param name="buffer">A parameter represents the Byte array to encode.</param>
        /// <param name="index">A parameter represents the position in the buffer indicating the start of the bytes to write.</param>
        /// <param name="count">A parameter represents the number of bytes to write.</param>
        public override void WriteBinHex(byte[] buffer, int index, int count)
        {
            this.originalXmlWriter.WriteBinHex(buffer, index, count);
            this.injectorXmlTextWriter.WriteBinHex(buffer, index, count);
        }

        /// <summary>
        ///  A method used to write out the specified name, ensuring it is a valid NmToken according to the W3C XML 1.0.
        /// </summary>
        /// <param name="name">A parameter represents the name to write.</param>
        public override void WriteNmToken(string name)
        {
            this.originalXmlWriter.WriteNmToken(name);
            this.injectorXmlTextWriter.WriteNmToken(name);
        }

        /// <summary>
        /// A method used to copy everything from the reader to the writer and moves the reader to the start of the next sibling.
        /// </summary>
        /// <param name="navigator">A parameter represents the System.Xml.XPath.XPathNavigator to copy from.</param>
        /// <param name="defattr">A parameter represents whether copy the default attributes from the XmlReader, true means copy, false means not copy.</param>
        public override void WriteNode(System.Xml.XPath.XPathNavigator navigator, bool defattr)
        {
            this.originalXmlWriter.WriteNode(navigator, defattr);
            this.injectorXmlTextWriter.WriteNode(navigator, defattr);
        }

        /// <summary>
        /// A method used to copy everything from the reader to the writer and moves the reader to the start of the next sibling.
        /// </summary>
        /// <param name="reader">A parameter represents the System.Xml.XmlReader to read from.</param>
        /// <param name="defattr">A parameter represents whether copy the default attributes from the XmlReader, true means copy, false means not copy.</param>
        public override void WriteNode(XmlReader reader, bool defattr)
        {
            this.originalXmlWriter.WriteNode(reader, defattr);
            this.injectorXmlTextWriter.WriteNode(reader, defattr);
        }

        /// <summary>
        /// A method used to write out the namespace-qualified name.
        /// </summary>
        /// <param name="localName">A parameter represents the local name to write.</param>
        /// <param name="ns">>A parameter represents the namespace URI for the name.</param>
        public override void WriteQualifiedName(string localName, string ns)
        {
            this.originalXmlWriter.WriteQualifiedName(localName, ns);
            this.injectorXmlTextWriter.WriteQualifiedName(localName, ns);
        }

        /// <summary>
        ///  A method used to write a System.Boolean value.
        /// </summary>
        /// <param name="value">A parameter represents the System.Boolean value to write.</param>
        public override void WriteValue(bool value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        ///  A method used to write a System.DateTime value.
        /// </summary>
        /// <param name="value">A parameter represents the System.DateTime value to write.</param>
        public override void WriteValue(DateTime value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        ///  A method used to write a System.Decimal value.
        /// </summary>
        /// <param name="value">A parameter represents the System.Decimal value to write.</param>
        public override void WriteValue(decimal value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        ///  A method used to write a System.Double value.
        /// </summary>
        /// <param name="value">A parameter represents the System.Double value to write.</param>
        public override void WriteValue(double value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        /// A method used to write a single-precision floating-point number.
        /// </summary>
        /// <param name="value">A parameter represents the single-precision floating-point number to write.</param>
        public override void WriteValue(float value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        ///  A method used to write a System.Int32 value.
        /// </summary>
        /// <param name="value">A parameter represents the System.Int32 value to write.</param>
        public override void WriteValue(int value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        /// A method used to write a System.Int64 value.
        /// </summary>
        /// <param name="value">A parameter represents the System.Int64 value to write.</param>
        public override void WriteValue(long value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        ///  A method used to write the object value.
        /// </summary>
        /// <param name="value">A parameter represents the object value to write.</param>
        public override void WriteValue(object value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }

        /// <summary>
        /// A method write a System.String value.
        /// </summary>
        /// <param name="value">A parameter represents the System.Boolean value to write.</param>
        public override void WriteValue(string value)
        {
            this.originalXmlWriter.WriteValue(value);
            this.injectorXmlTextWriter.WriteValue(value);
        }
    }
}