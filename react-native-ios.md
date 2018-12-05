

###自动链接
react-native link react-native-netease-im-pro

### 添加NIM SDK
```
NIMSDK.framework
NIMAVChat.framework
NMC.framework
NMCVideoFilter.bundle
```

### 添加其他 NIM SDK 依赖库

TARGETS->Build Phases-> Link Binary With Libaries中点击“+”按钮，选择

```$xslt
MobileCoreServices.framework
SystemConfiguration.framework
AVFoundation.framwork
CoreTelephony.framework
CoreMedia.framework
AudioToolbox.framework
VideoToolbox.framework
libc++.tbd 注2
libsqlite3.0.tbd
libz.tbd   
```

### 其他配置

- 在 Build Settings -> Other Linker Flags 里，添加选项 -ObjC。  

- 如果需要在后台时保持音频通话状态，在 Capabilities -> Background Modes 里 勾选 audio, airplay, and Picture in Picture。            
