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
            // initialize player with event id and bearer token
            let vc = PlayerVC.getPlayerVC(eventId:"6364efc88644b4cfc5bdafad", bearerToken: "eyJraWQiOiJqV3ZOTWZMK29jK2VjMklBWGt3emlodjh5dytFcEx2dFpwRnBiXC92ZmZMTT0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI0MDkxNTJlMi0xMDExLTQyYjItOWViMC1mOWQ2YzgyYmNlM2QiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmV1LWNlbnRyYWwtMS5hbWF6b25hd3MuY29tXC9ldS1jZW50cmFsLTFfTlE4bDMwbTd4IiwiY29nbml0bzp1c2VybmFtZSI6IjVhZWUzNDdjLThlYzMtNDkyYi1hZDgzLTQ3MjhlNTA5OWNkZCIsIm9yaWdpbl9qdGkiOiI4NGM1YjBiMS1hYzI0LTQxYTEtYTQwMS01ZmE3ZDViYmI3ZmIiLCJhdWQiOiIyNHZlcm02MzFjYWE1OTB0MnE3cnY1a2JrYyIsImV2ZW50X2lkIjoiZDdjMzgyOGEtNmM4Yi00OGM0LWE1OWMtMzQzMmQ3ZjlmN2E0IiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE2ODU3MDgyMTAsImV4cCI6MTY4NTcxMTgxMCwiaWF0IjoxNjg1NzA4MjEwLCJqdGkiOiIyYTI1ZmMzNy1kNjNjLTQyNTctOTNhNS01YmRkY2FmZjgzZmMiLCJlbWFpbCI6InNvZnR3YXJlQG1ha2VpdC1zdHVkaW8uY29tIn0.IgyJpf8pfUL2UoweImFNXV_98TWZBcWh4t_V0dLGfHIdh4GxKKBZ6zlbIy3nsK488X0fb6BAfvoy7aBhUb5QclLe_rO6jSYiEdPD3WeJV2dCFiSP5UKpagU5JEhVYTDIiyny6-qwvPd5thuPapyTlZWCmCMDpGVhMaSxiw1sddD3yzxDsGkB90zNvo9vh4rcO1Lu3yjfRscL10wvS11Os-eNZpVZFhA343t2aAgACjQ9ahptZEaAYMCtFlyhi9o7vE7QpAc9b4kUxTWELh-c_6cMGNga83todBXwLyj3dPR8cwfOq1FaGMIUVc4x2zURieBwtYopOPuS87_OG2YOOg")
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    
}

