

import Foundation
import UIKit

class ReView: UIViewController {
    
    @IBOutlet var lblQuestion: UITextView!
    @IBOutlet weak var mainQuestionTextview: UITextView!
    
    @IBOutlet weak var btnA: UIButton!
    @IBOutlet weak var btnB: UIButton!
    @IBOutlet weak var btnC: UIButton!
    @IBOutlet weak var btnD: UIButton!
    
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var preBtn: UIButton!
    
    @IBOutlet var bookBtn: UIButton!
    @IBOutlet weak var bookMarkBtn: UIButton!
    
    @IBOutlet weak var questionImage: UIImageView!
    @IBOutlet var mainQuestionView: UIView!
    @IBOutlet var lblQstn: UILabel!
    @IBOutlet var lblNote: UILabel!
    @IBOutlet var btnNote: UIButton!
    
    var color1 = UIColor(red: 243/255, green: 243/255, blue: 247/255, alpha: 1.0)
    
    var ReviewQues:[ReQuestion] = []
    var BookQuesList:[Question] = []
    var currentQuesPosition = 0
    
    var isInitial = true
    var Loader: UIAlertController = UIAlertController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setGradientBackground()
        
        //set opetion's view shadow
        self.SetViewWithShadow(views: btnA,btnB,btnC,btnD)
        
        //get bookmark list
        if (UserDefaults.standard.value(forKey: "booklist") != nil){
            BookQuesList = try! PropertyListDecoder().decode([Question].self, from:(UserDefaults.standard.value(forKey: "booklist") as? Data)!)
        }
        
       self.mainQuestionView.DesignViewWithShadow()
        
        // load question when view will appear
        currentQuesPosition = 0
        self.LoadQuestion()
    }
    
    @IBAction func msgButton(_ sender: Any) {
        let alert = UIAlertController(title: Apps.REPORT_QUESTION, message: "\(ReviewQues[currentQuesPosition].question)", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: {(textField)in
            textField.placeholder = Apps.TYPE_MSG
        })
        let okAction = UIAlertAction(title:Apps.SUBMIT, style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!)->Void in
            //submit question'snote to server
            if(Reachability.isConnectedToNetwork()){
                self.Loader = self.LoadLoader(loader: self.Loader)
                let apiURL = "question_id=\(self.ReviewQues[self.currentQuesPosition].id)&message=\( (alert.textFields![0].text)!)"
                print("API",apiURL)
                self.getAPIData(apiName: "report_question", apiURL: apiURL,completion: self.SubmitReview)
            }else{
                self.ShowAlert(title: Apps.NO_INTERNET_TITLE, message:Apps.NO_INTERNET_MSG)
            }
            
        })
        
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: Apps.CANCEL, style: .default, handler: { action in
           
        }))
        
        self.present(alert, animated: true)
    }
    
    //load sub category data here
    func SubmitReview(jsonObj:NSDictionary){
        // print("RS",jsonObj)
        let status = jsonObj.value(forKey: "error") as! Bool
        if (status) {
            self.Loader.dismiss(animated: true, completion: {
                self.ShowAlert(title: "Error", message:"\(jsonObj.value(forKey: "message")!)" )
            })
            
        }else{
            //get data for category
//            if let data = jsonObj.value(forKey: "data") as? [[String:Any]] {
//
//            }
        }
        //close loader here
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.45, execute: {
            DispatchQueue.main.async {
                self.DismissLoader(loader: self.Loader)
            }
        });
    }
    
    @IBAction func bookButton(_ sender: Any) {
        if(self.bookMarkBtn.tag == 0){
            let reQues = ReviewQues[currentQuesPosition]
            self.BookQuesList.append(Question.init(id: reQues.id, question: reQues.question, opetionA: reQues.opetionA, opetionB: reQues.opetionB, opetionC: reQues.opetionC, opetionD: reQues.opetionD, correctAns: reQues.correctAns, image: reQues.image, level: reQues.level, note: reQues.note))
            bookMarkBtn.setBackgroundImage(UIImage(named: "book-on"), for: .normal)
            bookMarkBtn.tag = 1
        }else{
            BookQuesList.removeAll(where: {$0.id == ReviewQues[currentQuesPosition].id && $0.correctAns == ReviewQues[currentQuesPosition].correctAns})
             bookMarkBtn.setBackgroundImage(UIImage(named: "book-off"), for: .normal)
            bookMarkBtn.tag = 0
        }
        
        UserDefaults.standard.set(try? PropertyListEncoder().encode(BookQuesList), forKey: "booklist")
    }

    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nxtButton(_ sender: Any) {
        if(currentQuesPosition  < ReviewQues.count - 1){
            currentQuesPosition += 1
            self.LoadQuestion()
        }
    }
    
    @IBAction func preButton(_ sender: Any) {
        if(currentQuesPosition >= 0){
            currentQuesPosition -= 1
            self.LoadQuestion()
        }
        
    }
    
    @IBAction func eNoteBtn(_ sender: Any) {
        lblNote.text = "\(ReviewQues[currentQuesPosition].note)"
    }
    
    @IBAction func BookmarkBtn(_ sender: Any) {
        let goHome = self.storyboard!.instantiateViewController(withIdentifier: "BookmarkView")
        self.present(goHome, animated: true, completion: nil)
        
    }
    
    // Set the background as a blue gradient
    func setGradientBackground() {
        let colorTop =  UIColor.black.cgColor
        let colorBottom = UIColor.blue.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    //load question
    func LoadQuestion(){
        
        ClearColor(btns: btnA,btnB,btnC,btnD)
        lblNote.text = ""
        
        if(ReviewQues.count  > currentQuesPosition && currentQuesPosition >= 0){
            lblQstn.text = "\(currentQuesPosition + 1)/\(Apps.TOTAL_PLAY_QS)"
            if(ReviewQues[currentQuesPosition].image == ""){
                // if question dose not have image set value here
                mainQuestionTextview.isHidden = false
                mainQuestionTextview.text = "\(ReviewQues[currentQuesPosition].question)"
                mainQuestionTextview.centerVertically()
                
                lblQuestion.isHidden = true
                questionImage.isHidden = true
            }else{
                // if question hase image set question values here
                lblQuestion.isHidden = false
                questionImage.isHidden = false
                
                lblQuestion.text = "\(ReviewQues[currentQuesPosition].question)"
                lblQuestion.centerVertically()
                
                mainQuestionTextview.isHidden = true
                
                DispatchQueue.main.async {
                    self.questionImage.loadImageUsingCache(withUrl: self.ReviewQues[self.currentQuesPosition].image)
                }
            }
            if ReviewQues[currentQuesPosition].note.isEmpty{
                btnNote.isHidden = true
            }else{
                btnNote.isHidden = false
            }
            
            //set options and question lable here
            btnA.setTitle("\(ReviewQues[currentQuesPosition].opetionA)", for: .normal)
            btnB.setTitle("\(ReviewQues[currentQuesPosition].opetionB)", for: .normal)
            btnC.setTitle("\(ReviewQues[currentQuesPosition].opetionC)", for: .normal)
            btnD.setTitle("\(ReviewQues[currentQuesPosition].opetionD)", for: .normal)
            
           CheckUserAnswer(userAnswer: ReviewQues[currentQuesPosition].userSelect)
            
            //check current question is in bookmark list or not
            if(BookQuesList.contains(where: {$0.id == ReviewQues[currentQuesPosition].id && $0.correctAns == ReviewQues[currentQuesPosition].correctAns})){
                self.bookMarkBtn.setBackgroundImage(UIImage(named: "book-on"), for: .normal)
                self.bookMarkBtn.tag = 1
            }else{
                self.bookMarkBtn.setBackgroundImage(UIImage(named: "book-off"), for: .normal)
                self.bookMarkBtn.tag = 0
            }
        }else{
            //question is over no more question to review
        }
    }
    
    func CheckUserAnswer(userAnswer:String){
        if ReviewQues[currentQuesPosition].opetionA == userAnswer{
            if ReviewQues[currentQuesPosition].correctAns == "a"{
                RightAnswer(opt: "a")
            }else{
                WrongAnswer(opt: "a", optRight: ReviewQues[currentQuesPosition].correctAns)
            }
        }else  if ReviewQues[currentQuesPosition].opetionB == userAnswer{
            if ReviewQues[currentQuesPosition].correctAns == "b"{
                RightAnswer(opt: "b")
            }else{
                WrongAnswer(opt: "b", optRight: ReviewQues[currentQuesPosition].correctAns)
            }
        }else  if ReviewQues[currentQuesPosition].opetionC == userAnswer{
            if ReviewQues[currentQuesPosition].correctAns == "c"{
                RightAnswer(opt: "c")
            }else{
                WrongAnswer(opt: "c", optRight: ReviewQues[currentQuesPosition].correctAns)
            }
        }else  if ReviewQues[currentQuesPosition].opetionD == userAnswer{
            if ReviewQues[currentQuesPosition].correctAns == "d"{
                RightAnswer(opt: "d")
            }else{
                WrongAnswer(opt: "d", optRight: ReviewQues[currentQuesPosition].correctAns)
            }
        }
    }
    //set right answer color to option
    func RightAnswer(opt:String){
        switch opt {
        case "a":
            btnA.backgroundColor = Apps.RIGHT_ANS_COLOR
            btnA.tintColor = UIColor.white
            break;
        case "b":
            btnB.backgroundColor = Apps.RIGHT_ANS_COLOR
            btnB.tintColor = UIColor.white
            break;
        case "c":
            btnC.backgroundColor = Apps.RIGHT_ANS_COLOR
            btnC.tintColor = UIColor.white
            break;
        case "d":
            btnD.backgroundColor = Apps.RIGHT_ANS_COLOR
            btnD.tintColor = UIColor.white
            break;
        default:
            print("unknown option selected")
        }
    }
    
    //set wrong answer and show user what is right answer
    func WrongAnswer(opt:String,optRight:String){
        //set wrong answer celor to view
        switch opt {
        case "a":
            btnA.backgroundColor = Apps.WRONG_ANS_COLOR
            btnA.tintColor = UIColor.white
            break;
        case "b":
            btnB.backgroundColor = Apps.WRONG_ANS_COLOR
            btnB.tintColor = UIColor.white
            break;
        case "c":
            btnC.backgroundColor = Apps.WRONG_ANS_COLOR
            btnC.tintColor = UIColor.white
            break;
        case "d":
            btnD.backgroundColor = Apps.WRONG_ANS_COLOR
            btnD.tintColor = UIColor.white
            break;
        default:
            print("unknown option selected")
        }
        
        //set right answer color to view
        RightAnswer(opt: optRight)
        
    }
    
    //reset options view color to default
    func ClearColor(btns:UIButton...){
        for btn in btns {
            btn.backgroundColor = UIColor.white
            btn.shadow(color: .lightGray, offSet: CGSize(width: 3, height: 3), opacity: 0.7, radius: 30, scale: true)
        }
    }
}