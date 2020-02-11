//
//  ViewController.swift
//  OnlineChatSdk
//
//  Created by bekannax on 11/15/2019.
//  Copyright (c) 2019 bekannax. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    @IBAction func openChat(_ sender: Any) {
//        let chatController = storyboard?.instantiateViewController(withIdentifier: "DemoChatController") as! DemoController
        let chatController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DemoChatController") as! DemoController
//        navigationController?.pushViewController(chatController, animated: true)
        navigationController?.present(chatController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

