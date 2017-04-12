//
//  EncryptionParser.swift
//  R2Streamer
//
//  Created by Alexandre Camilleri on 4/12/17.
//  Copyright © 2017 Readium. All rights reserved.
//

import Foundation
import AEXML

extension EncryptionParser: Loggable {}

public class EncryptionParser {

    /// Parse the <EncryptionProperties> containing <EncryptionProperty> child
    /// elements in order to fill the `Encryption`.
    ///
    /// - Parameters:
    ///   - encryptedDataElement: The <EncryptedData> parent element.
    ///   - encryption: The `Encryption` structure to fill.
    internal func parseEncryptionProperties(from encryptedDataElement: AEXMLElement,
                                               to encryption: inout Encryption)
    {
        guard let encryptionProperties = encryptedDataElement["EncryptionProperties"]["EncryptionProperty"].all else {
            log(level: .info, "Encryption parsing: no encryption properties.")
            return
        }
        //
        for encryptionProperty in encryptionProperties {
            parseCompressionElement(from: encryptionProperty, to: &encryption)
        }
    }

    /// Find the resource URI the encryptedDataElement is referencing, then look
    /// for an existing link in `publication` with an equal href.
    /// If found add `encryption` to the link properties.encryption.
    ///
    /// - Parameters:
    ///   - encryption: An `Encryption` instance.
    ///   - publication: The `Publication` where to look for
    ///   - encryptedDataElement: The xml element containing the encrypted
    ///                           resource's URI.
    internal func add(encryption: Encryption,
                      toLinkInPublication publication: inout Publication,
                      _ encryptedDataElement: AEXMLElement)
    {
        // Get the encryption data element associated ressource URI.
        if let resourceURI = encryptedDataElement["CipherData"]["CipherReference"].attributes["URI"] {
            // Find the ressource in Publication Links..
            if let link = publication.link(withHref: resourceURI) {
                if link.properties == nil {
                    link.properties = Properties()
                }
                link.properties.encryption = encryption
            }
        }
    }

    // Mark: - Fileprivate Methods.

    /// Parse the <Compression> element.
    ///
    /// - Parameters:
    ///   - encryptionProperty: The EncryptionProperty element, parent of
    ///                         <Compression>.
    ///   - encryption: The Encryption structure to fill.
    fileprivate func parseCompressionElement(from encryptionProperty: AEXMLElement,
                                             to encryption: inout Encryption)
    {
        // Check that we have a compression element, with originalLength, not empty.
        guard let compressionElement = encryptionProperty["Compression"].first,
            let originalLength = compressionElement.attributes["OriginalLength"],
            !originalLength.isEmpty else
        {
            return
        }
        encryption.originalLength = Int(originalLength)
        // Find the method attribute.
        guard let method = compressionElement.attributes["Method"] else {
            return
        }
        encryption.compression = (method == "8" ? "deflate" : "none")
    }
}
