package com.netease.im;


import android.app.Activity;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.netease.nim.avchatkit.AVChatKit;
import com.netease.nim.avchatkit.activity.AVChatActivity;

public class AvChatModule extends ReactContextBaseJavaModule {

    public AvChatModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @ReactMethod
    public void callAvChat(ReadableMap params, Promise promise){
        Activity activity = getCurrentActivity();
        String sessionId = params.getString("sessionId");
        String sessionName = params.getString("sessionName");
        //1: voice, 2: video
        String chatType = params.getString("chatType");
        AVChatKit.outgoingCall(activity, sessionId, sessionName, Integer.parseInt(chatType), AVChatActivity.FROM_INTERNAL);
    }

    @Override
    public String getName() {
        return "AvChatSession";
    }

}
