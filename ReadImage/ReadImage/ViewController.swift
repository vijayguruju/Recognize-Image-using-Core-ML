//
//  ViewController.swift
//  ReadImage
//
//  Created by Dinesh Sunder on 08/04/19.
//  Copyright © 2019 v2App. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var labelTxt: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var detectImg: UIButton!
    var imagePicker=UIImagePickerController()
    
    //Create a core model
    var model: Inceptionv3!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        
        detectImg.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        model = Inceptionv3()
    }
    
    // Pick Image Button Action
    
    @IBAction func imagePicker(_ sender: Any) {
        
            let alert=UIAlertController(title: "ReadImage", message: "Choose The photo from", preferredStyle: .actionSheet)
            let gallary=UIAlertAction(title: "Gallery", style: .default){ action -> Void in
                
                if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
                    self.imagePicker.sourceType = .photoLibrary;
                    self.imagePicker.allowsEditing = false
                    
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
            
            let camera=UIAlertAction(title: "Camera", style: .default) { action -> Void in
                
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self.imagePicker.sourceType = .camera
                    self.imagePicker.allowsEditing = false
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
                else {
                    let alertController = UIAlertController(title: "ReadImage", message:"No Camera",preferredStyle: UIAlertController.Style.alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                    
                    alertController.addAction(okAction)
                    //self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
            let cancel=UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
            alert.addAction(gallary)
            alert.addAction(camera)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)

    }
    
    //MARK:- ImagePicker Delegates
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)

    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        //Get the image
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        } //1
        
       
        imageView.image = image
        detectImg.isHidden = false

        
    }
    
    @IBAction func detectAction(_ sender: Any) {
        
        if  let image = self.imageView.image {
        //customize the image with size on Orientation
        labelTxt.text = "Analyzing Image..."

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        // Core ML
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        print("**** \n",prediction.classLabel)
        print(prediction.classLabelProbs)
        
        labelTxt.text = "\(prediction.classLabel)."
        
    }
    }
}
    


