Pod::Spec.new do |s|

s.name         = "MultichannelWidget"
s.version      = "1.1.7"
s.summary      = "Customer Chat integration."

s.homepage     = "http://qiscus.com"
# s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

s.license      = "MIT"

s.author       = { "juang@qiscus.co" => "juang@qiscus.co" }

s.platform     = :ios, "10.0"
s.swift_version = '4.2'
s.source       = { :git => "https://github.com/Qiscus-Integration/ios-multichannel-widget.git" }

s.source_files  = "MultichannelWidget", "Source/MultichannelWidget/**/*.{h,m,swift,xib}"

s.resources = "Source/MultichannelWidget/**/*.xcassets"
s.resource_bundles = {
    'MultichannelWidget' => ['Source/MultichannelWidget/**/*.{lproj,xib,xcassets,imageset,png}']
}

s.framework		= 'UIKit', 'AVFoundation'
s.requires_arc	= false

s.dependency 'Alamofire', '5.2'
s.dependency 'AlamofireImage'
s.dependency 'SwiftyJSON'
s.dependency 'QiscusCore'
s.dependency 'SDWebImage'

end
