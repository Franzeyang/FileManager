//
//  ViewController.swift
//  Unrar4iOS
//
//  Created by franze on 2017/6/11.
//  Copyright © 2017年 franze. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    var tableView:UITableView!
    var fileNameList = NSMutableArray()
    var filePathList = NSMutableArray()
    var pageNum = 0//当前目录的页码
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        let btn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 60, height: 40)))
        btn.center = view.center
        btn.setTitle("返回", for: .normal)
        btn.backgroundColor = UIColor.brown
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)//返回上级目录
        view.addSubview(btn)
        
        let fileManager = FileManager.default//获取文件FileManager的单例
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]//获取缓存路径
        let contents = try? fileManager.contentsOfDirectory(atPath: cachesPath)//获取缓存目录下的所有文件的名字
        print(cachesPath)
        
        let namelist = NSMutableArray()//存放当前目录下的所有文件的名字
        let pathlist = NSMutableArray()//存放当前目录下所有文件的路径
        
        namelist.addObjects(from: contents!)
        for name in namelist{
            let path = cachesPath + "/\(name)"//拼接文件路径
            pathlist.add(path)
        }
        
        fileNameList.add(namelist)//存放每个目录下的所有文件的名字
        filePathList.add(pathlist)//存放每个目录下的所有文件的路径
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let namelist = fileNameList[pageNum] as! NSMutableArray
        return namelist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let namelist = fileNameList[pageNum] as! NSMutableArray//获取当前目录下的所有文件名称
        cell.textLabel?.text = namelist[indexPath.row] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pathlist = filePathList[pageNum] as! NSMutableArray//获取当前目录下的所有文件的路径
        let filePath = pathlist[indexPath.row] as! String
        
        //判断是不是文件夹
        if isDirectory(filePath: filePath){
            fetchContentsOfDirectory(by: filePath)
            tableView.reloadData()
        }
        
        //判断是不是rar文件
        else if filePath.hasSuffix(".rar"){
            let namelist = fileNameList[pageNum] as! NSMutableArray
            let filename = namelist[indexPath.row] as! String
            let unrar4 = Unrar4iOS()//主角登场
            let queue = DispatchQueue(label: "queue")
            let alert = UIAlertController(title: nil, message: "正在解压", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            queue.async {
                unrar4.unRarByFranze(filePath: filePath, filename: filename)
                self.refresh()//刷新列表
                alert.dismiss(animated: true, completion: nil)
            }

        }
    }

    func fetchContentsOfDirectory(by directoryPath:String){
        let contents = try? FileManager.default.contentsOfDirectory(atPath: directoryPath)
        
        let namelist = NSMutableArray()//存放当前目录下的所有文件的名字
        let pathlist = NSMutableArray()//存放当前目录下所有文件的路径
        
        namelist.addObjects(from: contents!)
        for name in namelist{
            let path = directoryPath + "/\(name)"//拼接文件路径
            pathlist.add(path)
        }
        
        pageNum += 1
        
        fileNameList.add(namelist)
        filePathList.add(pathlist)
    }
    
    //判断是不是文件夹
    func isDirectory(filePath:String)->Bool{
        var isDir: ObjCBool = ObjCBool(false)
        let exits =  FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
        if isDir.boolValue && exits{
            return true
        }else{
            return false
        }
    }
    
    //重新获取当前目录下的文件列表
    func refresh(){
        let pathlist = filePathList[pageNum] as! NSMutableArray
        let path = pathlist.lastObject as! String
        let expression = ".+(?=/)"//匹配"/"前的文本，去掉最后的文件名；例：/1/2/3/4/5/6匹配的结果就是/1/2/3/4/5
        let regex = try? NSRegularExpression(pattern: expression, options: .allowCommentsAndWhitespace)
        let directory = regex?.matches(in: path, options: .reportProgress, range: NSRange(location: 0, length: (path as NSString).length))
        let currentPath = directory!.map({(path as NSString).substring(with: $0.range)}).last!//当前目录路径名
        
        let contents = try? FileManager.default.contentsOfDirectory(atPath: currentPath)
        
        let namelist = NSMutableArray()//存放当前目录下的所有文件的名字
        pathlist.removeAllObjects()
        namelist.addObjects(from: contents!)
        for name in namelist{
            let path = currentPath + "/\(name)"//拼接文件路径
            pathlist.add(path)
        }
        
        fileNameList.replaceObject(at: pageNum, with: namelist)
        filePathList.replaceObject(at: pageNum, with: pathlist)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    //返回上级目录
    func back(){
        if pageNum == 0{
        }else{
            fileNameList.removeObject(at: pageNum)
            filePathList.removeObject(at: pageNum)
            pageNum -= 1
            tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

//文件名转码
extension String{
    func latinToGBTEncoding()->String{
        let GBTEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        let data = self.data(using: .isoLatin1)
        return String(data: data!, encoding: String.Encoding(rawValue: GBTEnc))!
    }
}

extension Unrar4iOS{
    
    func unRarByFranze(filePath:String,filename:String){
        let directoryPath = filePath.replacingOccurrences(of: ".rar", with: "/")//先去掉".rar"后缀方便我们创建一个同名文件夹放置解压得到的文件
        //判断该文件夹是否存在，存在就创建一个
        if !FileManager.default.fileExists(atPath: directoryPath){
            try? FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)//创建文件夹
            //先判断是否解压成功
            if self.unrarOpenFile(filePath){
                let files = self.unrarListFiles()//解压得到一个包含所有文件名的数组
                for i in 0..<files!.count{
                    let name = (files?[i] as! String).latinToGBTEncoding()//这里是一个坑，解压后得到的文件名都是乱码
                    unRar_CreatDirectory(filename: name, filePath: directoryPath)//最让我头疼的地方，根据路径去一个一个创建文件夹
                    let path = directoryPath + name//拼接文件路径
                    if !FileManager.default.fileExists(atPath: path){
                        if let data = self.extractStream(files?[i] as! String){
                            FileManager.default.createFile(atPath: path, contents: data , attributes: nil)//创建文件
                        }
                    }
                }
            }
        }
    }
    
    private func unRar_CreatDirectory(filename:String,filePath:String){
        var string = filename
        let directoryList = NSMutableArray()
        let expression = "/"//通过查找"/"的个数查找文件夹的数量,比如/1/2/3/4/5这里就有5个文件夹
        let regex = try! NSRegularExpression(pattern: expression, options: .allowCommentsAndWhitespace)
        let numberOfMatches = regex.numberOfMatches(in: string, options:.reportProgress, range: NSMakeRange(0, (string as NSString).length))//获取匹配的个数,这里其实就是表示该路径下有多少文件夹，全部都要手动创建
        if numberOfMatches != 0{
            for _ in 0..<numberOfMatches{
                let expressionOfDir = ".+(?=/)"//匹配"/"前的文本，去掉最后的文件名；例：/1/2/3/4/5/6匹配的结果就是/1/2/3/4/5
                let regexOfDir = try? NSRegularExpression(pattern: expressionOfDir, options: .allowCommentsAndWhitespace)
                let directory = regexOfDir?.matches(in: string, options: .reportProgress, range: NSRange(location: 0, length: (string as NSString).length))//这里是匹配到的结果在字符串里区间值
                //根据上边得到的区间数组截取路径，得到了最后的文件夹名字，循环截取得到所有文件夹的路径
                string = directory!.map({(string as NSString).substring(with: $0.range)}).last!
                directoryList.add(string)//将截取到的文件夹路径放入数组
            }
        }
        if directoryList.count != 0{
            //因为是从最后的文件夹路径开始截取，所以要用倒序
            for str in directoryList.reversed(){
                if !FileManager.default.fileExists(atPath: filePath + (str as! String)){
                    try? FileManager.default.createDirectory(atPath: filePath + (str as! String), withIntermediateDirectories: true, attributes: nil)
                }
            }
        }
    }

}
