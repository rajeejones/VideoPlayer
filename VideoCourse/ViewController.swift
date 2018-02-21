//
//  ViewController.swift
//  VideoCourse
//
//  Created by Rajee Jones on 2/20/18.
//  Copyright © 2018 rajeejones. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playerButtonsView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var videoProgressSlider: UISlider!
    @IBOutlet weak var endDurationLabel: UILabel!
    @IBOutlet weak var startDurationLabel: UILabel!
    
    @objc var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isPlaying = false
    let videoURLString = "http://mirrors.standaloneinstaller.com/video-sample/jellyfish-25-mbps-hd-hevc.mp4"

    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = URL(string: videoURLString) else {
            print("No video to play")
            return
            
        }
        // Add Activity Indicator to view, hide play/pause buttons
        
        setupVideoPlayer(with: url)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // resizes the video on reside
        playerLayer.frame = videoView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        activityIndicator("Loading Video..")
       
    }
    
    
    func setupVideoPlayer(with videoURL: URL) {
        player = AVPlayer(url: videoURL)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: #keyPath(ViewController.player.timeControlStatus), options: [.new, .initial], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: #keyPath(ViewController.player.currentItem.isPlaybackLikelyToKeepUp), options: [.new, .initial], context: nil)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        videoView.layer.addSublayer(playerLayer)

        
        playButton.setImage(UIImage.imageFromSystemBarButton(.play), for: .normal)
        playButton.tintColor = UIColor.white
        
        rewindButton.setImage(UIImage.imageFromSystemBarButton(.rewind), for: .normal)
        rewindButton.tintColor = UIColor.white
        
        fastForwardButton.setImage(UIImage.imageFromSystemBarButton(.fastForward), for: .normal)
        fastForwardButton.tintColor = UIColor.white
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showPlayerButtons))
        videoView.addGestureRecognizer(tapRecognizer)
        
        videoView.bringSubview(toFront: playerButtonsView)
        videoView.bringSubview(toFront: progressContainerView)
        
    }
    
    func activityIndicator(_ title: String) {
        
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 160, height: 46))
        strLabel.text = title
        strLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        
        effectView.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2, y: view.frame.midY - strLabel.frame.height/2 , width: 160, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()
        
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        videoView.addSubview(effectView)
        videoView.bringSubview(toFront: effectView)
    }

    @objc func showPlayerButtons() {
        
        if self.playerButtonsView.alpha == 1 { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.playerButtonsView.alpha = 1
            self.progressContainerView.alpha = 1
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                self.playerButtonsView.alpha = 0
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.progressContainerView.alpha = 0
                })
                
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration",
        let durationSeconds = player.currentItem?.duration.seconds,
            durationSeconds > 0.0 {
            self.endDurationLabel.text = getTimeString(from: player.currentItem!.duration)
            self.startDurationLabel.text = "00:00"
        }
        
        // play when status is ready?
        if keyPath == "status" || keyPath == "timeControlStatus" || keyPath == #keyPath(ViewController.player.currentItem.isPlaybackLikelyToKeepUp) {
            if (player.status == .readyToPlay && player.timeControlStatus != .waitingToPlayAtSpecifiedRate && player.currentItem!.isPlaybackLikelyToKeepUp) {
                
                self.effectView.removeFromSuperview()
                player.play()
                playButton.setImage(UIImage.imageFromSystemBarButton(.pause), for: .normal)
                addTimeObserver()
                isPlaying = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.playerButtonsView.alpha = 0
                    })
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.progressContainerView.alpha = 0
                    })
                }
            } else if player.status == .failed {
                player.pause()
            }
        }
    }
    
    // MARK: - Helpers
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes, seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes, seconds])
        }
    }
    
    func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let currentItem = self?.player.currentItem else { return }
        
            self?.videoProgressSlider.maximumValue = Float(currentItem.duration.seconds)
            self?.videoProgressSlider.minimumValue = 0.0
            self?.videoProgressSlider.setValue(Float(currentItem.currentTime().seconds/currentItem.duration.seconds), animated: true)
            self?.endDurationLabel.text = self?.getTimeString(from: currentItem.currentTime())
            self?.startDurationLabel.text = self?.getTimeString(from: CMTime.init(seconds:(currentItem.duration.seconds - currentItem.currentTime().seconds), preferredTimescale:CMTimeScale(NSEC_PER_SEC)))
        })
    }
    
    // MARK: - Actions
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if isPlaying {
            player.pause()
            sender.setImage(UIImage.imageFromSystemBarButton(.pause), for: .normal)
            isPlaying = false
        } else if player.status == .readyToPlay {
            player.play()
            sender.setImage(UIImage.imageFromSystemBarButton(.play), for: .normal)
            isPlaying = true
        }
        
    }
    @IBAction func fastForwardButtonPressed(_ sender: UIButton) {
        // check if there is duration
        guard let duration = player.currentItem?.duration else { return }
        
        //skip 5 seconds if we can
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 5.0 // 5 seconds
        
        if newTime < (CMTimeGetSeconds(duration) - 5.0) {
            let time = CMTimeMake(Int64(newTime*1000), 1000)
            player?.seek(to: time)
        }
    }
    
    @IBAction func rewindButtonPressed(_ sender: UIButton) {

        //skip back 5 seconds if we can or go to the start
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 5.0 // 5 seconds
        
        if newTime < 0 {
            newTime = 0
        }
        let time = CMTimeMake(Int64(newTime*1000), 1000)
        player?.seek(to: time)
    }
    @IBAction func videoSliderScrubbed(_ sender: UISlider) {
        player.seek(to: CMTimeMake(Int64(sender.value*1000), 1000))
    }
    
    

}

extension UIImage{
    
    class func imageFromSystemBarButton(_ systemItem: UIBarButtonSystemItem, renderingMode:UIImageRenderingMode = .automatic)-> UIImage {
        
        let tempItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        
        // add to toolbar and render it
        let bar = UIToolbar()
        bar.setItems([tempItem], animated: false)
        bar.snapshotView(afterScreenUpdates: true)
        
        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView
        
        for view in itemView.subviews {
            if view is UIButton {
                let button = view as! UIButton
                let image = button.imageView!.image!
                image.withRenderingMode(renderingMode)
                return image
            }
        }
        
        return UIImage()
    }
}



