

import Foundation
import UIKit
import Firebase

class UpdateProfileView: UIViewController{
    
    @IBOutlet var btnUpdate: UIButton!
    @IBOutlet var usrImg: UIImageView!
    @IBOutlet var imgView: UIView!
    @IBOutlet var nameTxt: FloatingTF!
    @IBOutlet var nmbrTxt: FloatingTF!
    @IBOutlet var emailTxt: FloatingTF!
    
    var isInitial = true
    var Loader: UIAlertController = UIAlertController()
    
    var email = ""
    var dUser:User? = nil
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        dUser = try! PropertyListDecoder().decode(User.self, from: (UserDefaults.standard.value(forKey:"user") as? Data)!)
        
        imgView.layer.cornerRadius = imgView.frame.height/2
        
        self.usrImg.contentMode = .scaleAspectFill
        usrImg.clipsToBounds = true
        usrImg.layer.cornerRadius = usrImg.frame.height / 2
        
        nameTxt.text = dUser!.name
        nmbrTxt.text = dUser!.phone
        email = dUser!.email
        emailTxt.text = dUser?.email
       
        DispatchQueue.main.async {
            if(self.dUser!.image != ""){
                self.usrImg.loadImageUsingCache(withUrl: self.dUser!.image)
            }
        }
        
        self.hideKeyboardWhenTappedAround()
       
    }
    
    //load category data here
    func LoadData(jsonObj:NSDictionary){
        //print("RS",jsonObj)
        let status = jsonObj.value(forKey: "error") as! String
        if (status == "true") {
            self.Loader.dismiss(animated: true, completion: {
                self.ShowAlert(title: "Error", message:"\(jsonObj.value(forKey: "message")!)" )
            })
        }else{
            //get data for success response
        }
        //close loader here
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: {
            DispatchQueue.main.async {
                self.DismissLoader(loader: self.Loader)
                self.dUser!.name = self.nameTxt.text!
                self.dUser!.phone = self.nmbrTxt.text!
                
                UserDefaults.standard.set(try? PropertyListEncoder().encode(self.dUser), forKey: "user")
            }
        });
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cameraButton(_ sender: Any) {
        ImagePickerManager().pickImage(self, {image in
            self.usrImg.contentMode = .scaleAspectFill
            self.usrImg.image = image
            self.myImageUploadRequest()
        })
        
    }
    
    @IBAction func logoutBtn(_ sender: Any) {
        
        let alert = UIAlertController(title: Apps.LOGOUT_MSG,message: "",preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Apps.NO, style: UIAlertActionStyle.default, handler: {
            (alertAction: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: Apps.YES, style: UIAlertActionStyle.default, handler: {
            (alertAction: UIAlertAction!) in
            if Auth.auth().currentUser != nil {
                do {
                    try Auth.auth().signOut()
                    UserDefaults.standard.removeObject(forKey: "isLogedin")
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginView")
                    self.present(vc, animated: true, completion: nil)
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }))
        
        alert.view.tintColor = UIColor.black  // change text color of the buttons
        alert.view.layer.cornerRadius = 25   // change corner radius
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func policyButton(_ sender: Any) {
        let goHome = self.storyboard!.instantiateViewController(withIdentifier: "PrivacyView")
        self.present(goHome, animated: true, completion: nil)
    }
    
    @IBAction func termsButton(_ sender: Any) {
        let goHome = self.storyboard!.instantiateViewController(withIdentifier: "TermsView")
        self.present(goHome, animated: true, completion: nil)
    }
    
    @IBAction func updateButton(_ sender: Any) {
        //get data from server
        if(Reachability.isConnectedToNetwork()){
            Loader = LoadLoader(loader: Loader)
            let apiURL = "email=\(emailTxt.text)&name=\(nameTxt.text)&mobile=\(nmbrTxt.text)"
            self.getAPIData(apiName: "update_profile", apiURL: apiURL,completion: LoadData)
        }else{
            ShowAlert(title: Apps.NO_INTERNET_TITLE, message:Apps.NO_INTERNET_MSG)
        }
    }
    
    func myImageUploadRequest(){
        
        let url = URL(string: Apps.URL)
        var request = URLRequest(url:url!);
        request.httpMethod = "POST";
        let user_id = "\(self.dUser!.userID)"
        let param = [
            "access_key"  : "6808",
            "upload_profile_image"    : "1",
            "user_id"    : user_id
        ]
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let imageData = UIImageJPEGRepresentation(self.usrImg.image!, 0.5)
      
        if(imageData==nil)  {return; }
        
        request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "image", imageDataKey: imageData!, boundary: boundary) as Data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {             // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {   // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                return
            }
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
                if (jsonObj != nil)  {
                    print("JSON",jsonObj!)
                    let status = jsonObj!.value(forKey: "error") as! NSNumber as! Bool
                    if (status) {
                        self.Loader.dismiss(animated: true, completion: {
                            self.ShowAlert(title: "Error", message:"\(jsonObj!.value(forKey: "message")!)" )
                        })
                        
                    }else{
                        //get data for success response
                       // imageCache.removeObject(forKey: self.dUser!.image as NSString)
                        self.dUser?.image = jsonObj!.value(forKey: "file_path") as! String
                        UserDefaults.standard.set(try? PropertyListEncoder().encode(self.dUser), forKey: "user")
                    }
                }else{
                }
            }
        }
        task.resume()
        
    }
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: Data, boundary: String) -> Data {
        var body = Data();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        let filename = "\(Date().currentTimeMillis()).jpg"
        let mimetype = "image/jpg"
        
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey as Data)
        body.appendString(string: "\r\n")
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}