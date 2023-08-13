//
//  ListViewController.swift
//  MapKitApp
//
//  Created by Mustafa Kemal ARDA on 5.08.2023.
//

import UIKit
import CoreData


class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var choosenLocationName = ""
    var choosenLocationId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))
        
        getData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("createNewPlace"), object: nil)
    }
    
    
    
    @objc func getData() {
        
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
                
                nameArray.removeAll(keepingCapacity: false)
                idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] {
                    
                    if let name = result.value(forKey: "name") as? String{
                        nameArray.append(name)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        idArray.append(id)
                    }
                }
                
                tableView.reloadData()
                
            }
        } catch {
            print("error!")
        }
    }
    
    @objc func addButtonClicked() {
        choosenLocationName = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenLocationName = nameArray[indexPath.row]
        choosenLocationId = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.choosenName = choosenLocationName
            destinationVC.choosenId = choosenLocationId
        }
    }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
            if editingStyle == .delete {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
                let uuidString = idArray[indexPath.row].uuidString
                
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    
                    let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        
                        
                        for result in results as! [NSManagedObject] {
                            
                            if let id = result.value(forKey: "id") as? UUID {
                                if id == idArray[indexPath.row] {
                                    
                                    context.delete(result)
                                    nameArray.remove(at: indexPath.row)
                                    idArray.remove(at: indexPath.row)
                                    
                                    self.tableView.reloadData()
                                    
                                    do {
                                        try context.save()
                                        
                                    } catch {
                                        
                                    }
                                    
                                    break
                                }
                            }
                            
                        }
                        
                    }
                    
                } catch {
                    print("error!")
                }
                
                
            }
        }
        
        
        
        
    }
    
    

