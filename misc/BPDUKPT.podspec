# vim: set ft=ruby fenc=utf-8 sw=2 ts=2 et:
#
#  BPDUKPT - Decrypt the magnatic strips and extract the encrypted tracks into track 1, track 2, track 3 and KSN
#
#      http://github.com/leomayleomay/BPDUKPT
#
#  Use and distribution licensed under the BSD license.  See
#  the LICENSE file for full text.
#
#  Authors:
#      Hao Liu <leomayleomay@gmail.com>
#
#

Pod::Spec.new do |s|
  s.name = 'BPDUKPT'
  s.version = '0.1'
  s.license = { :type => 'BSD', :file => 'LICENSE' }
  s.summary = 'Decrypt utility of the IDTech card reader for iOS'
  s.homepage = 'https://github.com/leomayleomay/BPDUKPT'
  s.author = { 'Hao Liu' => 'leomayleomay@gmail.com' }
  s.source = { :git => 'https://github.com/leomayleomay/BPDUKPT.git', :tag => '0.1' }
  s.source_files = 'src/*.{h,m}'
  s.requires_arc = true

  s.ios.deployment_target = '4.3'
end
