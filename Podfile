platform :ios, '8.0'

pre_install do |installer|
	puts 'pre_install begin....'
	dir_af = File.join(installer.sandbox.pod_dir('AFNetworking'), 'UIKit+AFNetworking')
	Dir.foreach(dir_af) {|x|
		real_path = File.join(dir_af, x)
		if (!File.directory?(real_path) && File.exists?(real_path))
			if((x.start_with?('UIWebView') || x == 'UIKit+AFNetworking.h'))
				File.delete(real_path)
				puts 'delete:'+ x
			end
		end
	}
	puts 'end pre_install.'
end

target "Leanote" do

pod 'AFNetworking', '2.6.3'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'CocoaLumberjack', '~>2.0', :inhibit_warnings => true
pod 'UIAlertView+Blocks', '~>0.8.1', :inhibit_warnings => true
pod 'WordPress-iOS-Shared', '0.5.2', :inhibit_warnings => true
pod 'WordPressCom-Analytics-iOS', '~>0.0.4', :inhibit_warnings => true

pod 'CTAssetsPickerController',  '~> 2.9.0'

pod 'SWTableViewCell', '~> 0.3.7'

pod 'SGNavigationProgress'

pod 'QBImagePickerController', '~> 3.0.0'

pod 'WPMediaPicker'

end
