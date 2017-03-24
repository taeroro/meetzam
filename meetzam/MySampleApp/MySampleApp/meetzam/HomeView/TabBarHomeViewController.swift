//
//  TabBarHomeViewController.swift
//  MySampleApp
//
//  Created by ZuYuan Fan on 2/20/17.
//
//  Mushroom05:
//      adding global movie array in variables section
//      adding handler function
//      import AWS dynamodb

import UIKit
import AWSDynamoDB
import AWSMobileHubHelper

class TabBarHomeViewController:  UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    
    // ============================================
    // Variable starts here
    var new_signinObserver: AnyObject!
    var new_signoutObserver: AnyObject!
    
    var isFirstMovieView = false
    //mush
    var movielist = MovieList()
    var movieView = FrameViewController()
    var user_p = UserProfileToDB()
    
    // Variable ends here
    // ============================================
    // Change status bar type to default.
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Let self be the delegate and dataSource
        self.delegate = self
        self.dataSource = self
        
        //get user liked movies initially
        UserProfileToDB().getLikedMovies(userId: AWSIdentityManager.default().identityId!, user_profile: user_p!)
        //get homescreen movie list
        //actually if we discard the executor; mainThread(),
        //we might be able to discard the movieView thingy
        //since without that the method will run asynchronizedly and return immediately
        SingleMovie().refreshList(movie_list: movielist, view: movieView, user_profile: user_p!)
        
        // change background color to grey
        //view.backgroundColor = UIColor.init(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        view.backgroundColor = UIColor.init(red: 233/255, green: 233/255, blue: 233/255, alpha: 1)
        
        // This is the first movie
        if (!AWSIdentityManager.default().isLoggedIn) {
            self.isFirstMovieView = true
        }
        
        let frameVC = movieView
        let viewControllers = [frameVC]
        
        // let viewControllers = [movieView]
        setViewControllers(viewControllers, direction: .forward, animated: true, completion: nil)
        
        // ============================================
        // AWS implementation starts here
        // 1. first attempt to pop sign in view controller
        perform(#selector(popSignInViewController), with: nil, afterDelay: 0)
        
        // 2. signinObserver: need to figure it out.
        new_signinObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AWSIdentityManagerDidSignIn,
            object: AWSIdentityManager.default(),
            queue: OperationQueue.main,
            using: { [weak self] (note: Notification) -> Void in
                guard let strongSelf = self else { return }
                print("Sign in observer observed sign in.")
        })
        
        // 3. signoutObserver: need to figure it out.
        new_signoutObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AWSIdentityManagerDidSignOut,
            object: AWSIdentityManager.default(),
            queue: OperationQueue.main,
            using: { [weak self] (note: Notification) -> Void in
                guard let strongSelf = self else { return }
                print("Sign Out Observer observed sign out.")
        })
        
        // AWS implementation ends here
        // ============================================
        
    }
    
    // ============================================
    // AWS support functions start here
    deinit {
        NotificationCenter.default.removeObserver(new_signinObserver)
        NotificationCenter.default.removeObserver(new_signoutObserver)
    }
    
    // display sign in view controller
    func popSignInViewController() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        if (!AWSIdentityManager.default().isLoggedIn) {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            self.present(viewController, animated: false, completion: nil)
            
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // AWS support functions end here
    // ============================================
    // Page view functions start here
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let currentMovie = (viewController as! FrameViewController).movie_info
        let currentIndex = movielist.tableRows.index(of: currentMovie!)
        
        if (currentIndex! < (movielist.tableRows.count) - 1) {
            let frameVC = FrameViewController()
            frameVC.movie_info = movielist.tableRows[currentIndex! + 1]
            print ("liked movies are " + (user_p?.currentLikedMovie.description)!)
            print("next movie is" + (frameVC.movie_info?.title)!)
            //mush: like
            if (user_p?.currentLikedMovie.contains((frameVC.movie_info?.title)!))! {
                print("swipe left:FOUND THE MOVIE IN LIKED LIST")
                frameVC.like = true
            }
            else {
                print("swipe left:NOT LIKED")
            }
            
            // turn off isFirstMovieView
            self.isFirstMovieView = false
            
            user_p?.currentLikedMovie.removeAll()
            UserProfileToDB().getLikedMovies(userId: AWSIdentityManager.default().identityId!, user_profile: user_p!)
            
            return frameVC
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let currentMovie = (viewController as! FrameViewController).movie_info
        let currentIndex = movielist.tableRows.index(of: currentMovie!)
        
        if (currentIndex! > 0) {
            let frameVC = FrameViewController()
            frameVC.movie_info = movielist.tableRows[currentIndex! - 1]
            
            print ("liked movies are " + (user_p?.currentLikedMovie.description)!)
            print("next movie is" + (frameVC.movie_info?.title)!)
            //mush: like
            if (user_p?.currentLikedMovie.contains((frameVC.movie_info?.title)!))! {
                print("swipe right:FOUND THE MOVIE IN LIKED LIST")
                frameVC.like = true
            }
            else {
                print("swipe right:NOT LIKED")
            }
            
            
            // turn off isFirstMovieView
            self.isFirstMovieView = false
            
            user_p?.currentLikedMovie.removeAll()
            UserProfileToDB().getLikedMovies(userId: AWSIdentityManager.default().identityId!, user_profile: user_p!)
            
            return frameVC
        }
        
        return nil
        
    }
    
    // current viewcontroller
    override func viewWillAppear(_ animated: Bool) {
        if (isFirstMovieView && AWSIdentityManager.default().isLoggedIn) {
            viewDidLoad()
        }
    }
    
    // Page view functions end here
    // ============================================
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This is each page's view controller
class FrameViewController: UIViewController {
    
    // DB related var
    var user_p = UserProfileToDB()
    var like = false
    var movie_info = SingleMovie()
    
    // UI var
    let movieTitle = UILabel()
    let movieDetailedInfo = UITextView()
    
    // scoll view
    let movieContent = UIScrollView(frame: CGRect(x: 0, y: 22, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 46))
    
    // image view init
    var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 110)
        
        return iv
    }()
    
    // Big Heart image
    let likeImage: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Liked")
        iv.contentMode = .scaleAspectFill
        
        return iv
    }()
    
    let doHeartButton: UIButton = {
        let bt = UIButton()
        bt.setImage(UIImage(named: "DoHeart"), for: .normal)
        bt.addTarget(self, action: #selector(FrameViewController.cancelLike), for: .touchUpInside)
        
        return bt
    }()
    
    // Small heart button action (cancel like)
    func cancelLike() {
        print("unliked!!!!!!!")
        
        // unlike animation
        UIView.animate(withDuration: 0.1 / 1.5, animations: {() -> Void in
            self.doHeartButton.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: {(_ finished: Bool) -> Void in
            UIView.animate(withDuration: 0.1 / 2, animations: {() -> Void in
                self.doHeartButton.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8)
            }, completion: {(_ finished: Bool) -> Void in
                UIView.animate(withDuration: 0.1 / 2, animations: {() -> Void in
                    self.doHeartButton.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                }, completion: {(finished: Bool) in
                    self.doHeartButton.alpha = 0
                    self.doHeartButton.transform = CGAffineTransform.identity
                    self.doHeartButton.removeFromSuperview()
                })
            })
        })
    }
    
    // Double Tap action
    func doubleTapAction() {
        UserProfileToDB().insertToCurrentLikedMovie(key: AWSIdentityManager.default().identityId!, movieTitle: movieTitle.text!)
        imageView.isUserInteractionEnabled = false // in case if the user trying to do multiple double tap in a short time
        let newX = imageView.bounds.width
        let newY = imageView.bounds.height
        likeImage.frame = CGRect(x: newX * 0.4, y: newY * 0.4, width: newX * 0.2, height: newY * 0.2)
        likeImage.alpha = 0.98
        imageView.addSubview(likeImage)
        
        // pop up
        likeImage.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.2 / 1.5, animations: {() -> Void in
            self.likeImage.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
        }, completion: {(_ finished: Bool) -> Void in
            UIView.animate(withDuration: 0.2 / 2, animations: {() -> Void in
                self.likeImage.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9)
            }, completion: {(_ finished: Bool) -> Void in
                UIView.animate(withDuration: 0.2 / 2, animations: {() -> Void in
                    self.likeImage.transform = CGAffineTransform.identity
                }, completion: {(finished: Bool) in
                    // fade out
                    UIView.animate(withDuration: 0.2, delay: 0.3, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.likeImage.alpha = 0
                    }, completion: {(finished: Bool) in
                        self.likeImage.removeFromSuperview()
                        self.imageView.isUserInteractionEnabled = true // reenable the double tap
                    })
                })
            })
        })
        
        // do heart button create
        self.doHeartButton.alpha = 1
        doHeartButton.frame = CGRect(x: 10 + movieTitle.frame.width, y: imageView.frame.height + 10, width: 25, height: 25)
        movieContent.addSubview(doHeartButton)
        
        // do heart button animation
        doHeartButton.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.2 / 1.5, animations: {() -> Void in
            self.doHeartButton.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
        }, completion: {(_ finished: Bool) -> Void in
            UIView.animate(withDuration: 0.2 / 2, animations: {() -> Void in
                self.doHeartButton.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9)
            }, completion: {(_ finished: Bool) -> Void in
                UIView.animate(withDuration: 0.2 / 2, animations: {() -> Void in
                    self.doHeartButton.transform = CGAffineTransform.identity
                }, completion: nil)
            })
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // view changes
        self.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.view.backgroundColor = UIColor.clear
        //mush
        //SingleMovie().getMovieForDisplay(key: imagekey!, movie_data: movie_info, movieTitle: movieTitle, movieTitleDetailed: movieDetailedInfo, imageView: imageView, moviePopInfo: moviePopInfo)
        movieTitle.text = movie_info?.title
        movieDetailedInfo.text = movie_info?.longDescription
        
        imageView.image = movie_info?.image
        //moviePopInfo.text = movie_info?.pop
        
        // add scroll view
        movieContent.showsVerticalScrollIndicator = true
        movieContent.isScrollEnabled = true
        movieContent.isUserInteractionEnabled = true
        movieContent.backgroundColor = UIColor.clear
        self.view.addSubview(movieContent)
        movieContent.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height*1.775)
        
        // add image view to scroll view
        imageView.isUserInteractionEnabled = true
        let doubletap = UITapGestureRecognizer()
        doubletap.numberOfTapsRequired = 2;
        doubletap.addTarget(self, action: #selector(FrameViewController.doubleTapAction))
        imageView.addGestureRecognizer(doubletap)
        movieContent.addSubview(imageView)
        
        // add movie title in to the scroll view
        movieTitle.frame = CGRect(x: 10, y: imageView.frame.height + 5, width: UIScreen.main.bounds.width - 50, height: 30)
        movieTitle.font = UIFont(name: "HelveticaNeue-Light", size: 23)
        movieTitle.textColor = UIColor.black
        movieContent.addSubview(movieTitle)
        
        // add movie info in to the scroll view
        movieDetailedInfo.frame = CGRect(x: 6, y: imageView.frame.height + movieTitle.frame.height + 5, width: UIScreen.main.bounds.width - 15, height: 200)
        movieDetailedInfo.font = UIFont(name: "HelveticaNeue-thin", size: 15)
        movieDetailedInfo.textColor = UIColor.black
        movieDetailedInfo.backgroundColor = UIColor.clear
        movieDetailedInfo.isEditable = false
        movieContent.addSubview(movieDetailedInfo)
        
        // add small heart
        if (like) {
            // do heart button create
            self.doHeartButton.alpha = 1
            doHeartButton.frame = CGRect(x: 10 + movieTitle.frame.width, y: imageView.frame.height + 10, width: 25, height: 25)
            movieContent.addSubview(doHeartButton)
        }
    }
}
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Might need it..?

//    let moviePopInfo = UILabel()

//            doHeart.frame = CGRect(x: 10 + movieTitle.frame.width, y: imageView.frame.height + 10, width: 25, height: 25)
//            doHeart.alpha = 0.98
//            imageView.addSubview(doHeart)

//        // do heart
//        doHeart.frame = CGRect(x: 10 + movieTitle.frame.width, y: imageView.frame.height + 10, width: 25, height: 25)
//        doHeart.alpha = 0.98
//        imageView.addSubview(doHeart)

// pop up do heart
//        doHeart.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
//        UIView.animate(withDuration: 0.1 / 1.5, animations: {() -> Void in
//            self.doHeart.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
//        }, completion: {(_ finished: Bool) -> Void in
//            UIView.animate(withDuration: 0.1 / 2, animations: {() -> Void in
//                self.doHeart.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9)
//            }, completion: {(_ finished: Bool) -> Void in
//                UIView.animate(withDuration: 0.1 / 2, animations: {() -> Void in
//                    self.doHeart.transform = CGAffineTransform.identity
//                }, completion: nil)
//            })
//        })


// Scroll down action
//    func scrollUpAction() {
//        print("scrolled down")
//    }

// add scroll down to view the detailed stuff
//        let scrolldown = UISwipeGestureRecognizer()
//        scrolldown.direction = .up
//        scrolldown.addTarget(self, action: #selector(FrameViewController.scrollUpAction))
//        imageView.addGestureRecognizer(scrolldown)
