//
//  ViewController.swift
//  AV360
//
//  Created by sajidnawaz993@gmail.com on 05/31/2023.
//  Copyright (c) 2023 sajidnawaz993@gmail.com. All rights reserved.
//

import UIKit
import AV360

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func av360btntpd(_ sender: Any) {
            // initialize player with user id and bearer token
            let vc = PlayerVC.getPlayerVC(userId: "6364efc88644b4cfc5bdafad", bearerToken: "")
            self.present(vc, animated: true)
        }
    
}

