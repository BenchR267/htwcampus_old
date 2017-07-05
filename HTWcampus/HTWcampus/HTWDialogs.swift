//
//  HTWDialogs.swift
//  HTWcampus
//
//  Created by Benjamin Herzog on 05.07.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

@objc class HTWDialogs: NSObject {
    
    private static let url = "https://www.htw-dresden.de/fileadmin/userfiles/htw/img/HTW-App/api/dialogs.json"
    
    class func triggerDialogs() {
        
        URLSession.shared.dataTask(with: URL(string: url)!) { data, _, _ in
            
            guard
                let data = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                let dialogs = jsonObject as? [[String: String]]
            else {
                    return
            }
            
            for dialog in dialogs {
                if dialog["id"].map(wasShownBefore(dialog:)) ?? false {
                    continue
                }
                
                let title = dialog["title"] ?? "Information"
                guard let message = dialog["message"] else { continue }
                let cta = dialog["cta"] ?? "Ok"
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: cta, style: .default, handler: nil))
                DispatchQueue.main.async {
                    guard let vc = UIApplication.shared.delegate?.window??.rootViewController else {
                        return
                    }
                    vc.present(alert, animated: true, completion: {
                        if let id = dialog["id"] {
                            saveIdAsShown(id: id)
                        }
                    })
                }
            }
        }.resume()
        
    }
    
    private class func dialogKey(id: String) -> String {
        return "DialogKey_\(id)"
    }
    
    private class func wasShownBefore(dialog id: String) -> Bool {
        let key = dialogKey(id: id)
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private class func saveIdAsShown(id: String) {
        let key = dialogKey(id: id)
        UserDefaults.standard.set(true, forKey: key)
    }
    
}
