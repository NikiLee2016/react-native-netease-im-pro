package com.netease.im.common;

import android.content.Context;
import android.graphics.Bitmap;
import android.text.TextUtils;
import android.view.View;

import com.netease.im.IMApplication;
import com.netease.im.R;
import com.netease.im.uikit.common.media.BitmapUtil;
import com.netease.im.uikit.common.util.log.LogUtil;
import com.netease.nimlib.sdk.nos.model.NosThumbParam;
import com.netease.nimlib.sdk.nos.util.NosThumbImageUtil;
import com.netease.nimlib.sdk.uinfo.model.UserInfo;
import com.nostra13.universalimageloader.cache.disc.impl.ext.LruDiskCache;
import com.nostra13.universalimageloader.cache.disc.naming.Md5FileNameGenerator;
import com.nostra13.universalimageloader.cache.memory.impl.LruMemoryCache;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;
import com.nostra13.universalimageloader.core.assist.FailReason;
import com.nostra13.universalimageloader.core.assist.ImageSize;
import com.nostra13.universalimageloader.core.download.BaseImageDownloader;
import com.nostra13.universalimageloader.core.download.ImageDownloader;
import com.nostra13.universalimageloader.core.listener.ImageLoadingListener;
import com.nostra13.universalimageloader.utils.MemoryCacheUtils;
import com.nostra13.universalimageloader.utils.StorageUtils;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 图片加载、缓存、管理组件
 */
public class ImageLoaderKit {
    public static final int DEFAULT_AVATAR_THUMB_SIZE = (int) IMApplication.getContext().getResources().getDimension(R.dimen.avatar_max_size);
    public static final int DEFAULT_AVATAR_NOTIFICATION_ICON_SIZE = (int) IMApplication.getContext().getResources().getDimension(R.dimen.avatar_notification_size);


    /**
     * 生成头像缩略图NOS URL地址（用作ImageLoader缓存的key）
     */
    private static String makeAvatarThumbNosUrl(final String url, final int thumbSize) {
        return thumbSize > 0 ? NosThumbImageUtil.makeImageThumbUrl(url, NosThumbParam.ThumbType.Crop, thumbSize, thumbSize) : url;
    }

    public static String getAvatarCacheKey(final String url) {
        return makeAvatarThumbNosUrl(url, DEFAULT_AVATAR_THUMB_SIZE);
    }

    private static final String TAG = ImageLoaderKit.class.getSimpleName();

    private static final int M = 1024 * 1024;

    private Context context;

    private static List<String> uriSchemes;

    public ImageLoaderKit(Context context, ImageLoaderConfiguration config) {
        this.context = context;
        init(config);
    }

    private void init(ImageLoaderConfiguration config) {
        try {
            ImageLoader.getInstance().init(config == null ? getDefaultConfig() : config);
        } catch (IOException e) {
            LogUtil.e(TAG, "init ImageLoaderKit error, e=" + e.getMessage().toString());
        }

        LogUtil.w(TAG, "init ImageLoaderKit completed");
    }

    public void clear() {
        ImageLoader.getInstance().clearMemoryCache();
        cacheLoad.clear();
    }

    public void clearCache(){
//        clear();
        ImageLoader.getInstance().clearDiskCache();
    }

    public File getChacheDir(){
       return StorageUtils.getOwnCacheDirectory(context, context.getPackageName() + "/cache/image/");
    }

    private ImageLoaderConfiguration getDefaultConfig() throws IOException {
        int MAX_CACHE_MEMORY_SIZE = (int) (Runtime.getRuntime().maxMemory() / 8);
        File cacheDir = getChacheDir();

        LogUtil.w(TAG, "ImageLoader memory cache size = " + MAX_CACHE_MEMORY_SIZE / M + "M");
        LogUtil.w(TAG, "ImageLoader disk cache directory = " + cacheDir.getAbsolutePath());

        ImageLoaderConfiguration config = new ImageLoaderConfiguration
                .Builder(context)
                .threadPoolSize(3) // 线程池内加载的数量
                .threadPriority(Thread.NORM_PRIORITY - 2) // 降低线程的优先级，减小对UI主线程的影响
                .denyCacheImageMultipleSizesInMemory()
                .memoryCache(new LruMemoryCache(MAX_CACHE_MEMORY_SIZE))
                .diskCache(new LruDiskCache(cacheDir, new Md5FileNameGenerator(), 0))
                .defaultDisplayImageOptions(DisplayImageOptions.createSimple())
                .imageDownloader(new BaseImageDownloader(context, 5 * 1000, 30 * 1000)) // connectTimeout (5 s), readTimeout (30 s)超时时间
                .writeDebugLogs()
                .build();

        return config;
    }


    /**
     * 判断图片地址是否合法，合法地址如下：
     * String uri = "http://site.com/image.png"; // from Web
     * String uri = "file:///mnt/sdcard/image.png"; // from SD card
     * String uri = "content://media/external/audio/albumart/13"; // from content provider
     * String uri = "assets://image.png"; // from assets
     * String uri = "drawable://" + R.drawable.image; // from drawables (only images, non-9patch)
     */
    public static boolean isImageUriValid(String uri) {
        if (TextUtils.isEmpty(uri)) {
            return false;
        }

        if (uriSchemes == null) {
            uriSchemes = new ArrayList<>();
            for (ImageDownloader.Scheme scheme : ImageDownloader.Scheme.values()) {
                uriSchemes.add(scheme.name().toLowerCase());
            }
        }

        for (String scheme : uriSchemes) {
            if (uri.toLowerCase().startsWith(scheme)) {
                return true;
            }
        }

        return false;
    }

    /**
     * 构建头像缓存
     */
    public static void buildAvatarCache(List<String> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }

        UserInfo userInfo;
        for (String account : accounts) {
            userInfo = IMApplication.getUserInfoProvider().getUserInfo(account);
            if (userInfo != null) {
                asyncLoadAvatarBitmapToCache(userInfo.getAvatar());
            }
        }

        LogUtil.w(TAG, "build avatar cache completed, avatar count =" + accounts.size());
    }

    /**
     * 获取通知栏提醒所需的头像位图，只存内存缓存中取，如果没有则返回空，自动发起异步加载
     */
    public static Bitmap getNotificationBitmapFromCache(String url) {
        Bitmap cachedBitmap = getMemoryCachedAvatarBitmap(url);
        if (cachedBitmap == null) {
            asyncLoadAvatarBitmapToCache(url);
        } else {
            return BitmapUtil.resizeBitmap(cachedBitmap,
                    DEFAULT_AVATAR_NOTIFICATION_ICON_SIZE,
                    DEFAULT_AVATAR_NOTIFICATION_ICON_SIZE);
        }

        return null;
    }

    /**
     * 从ImageLoader内存缓存中取出头像位图
     */
    private static Bitmap getMemoryCachedAvatarBitmap(String url) {
        if (url == null || !isImageUriValid(url)) {
            return null;
        }

        String key = getAvatarCacheKey(url);

//         DiskCacheUtils.findInCache(uri, ImageLoader.getInstance().getDiskCache() 查询磁盘缓存示例
        List<Bitmap> bitmaps = MemoryCacheUtils.findCachedBitmapsForImageUri(key, ImageLoader.getInstance().getMemoryCache());
        if (bitmaps.size() > 0) {
            return bitmaps.get(0);
        }

        return null;
    }

    public static String getMemoryCachedAvatar(String url) {//TODO
        return "";
//        if (url == null || !isImageUriValid(url)) {
//            return "";
//        }
//        String key = getAvatarCacheKey(url);
//
//        File file = DiskCacheUtils.findInCache(key, ImageLoader.getInstance().getDiskCache());// 查询磁盘缓存示例
//        if (file == null) {
////            asyncLoadAvatarBitmapToCache(url);
//        }
//        return file == null ? "" : file.getAbsolutePath();
    }

    private static Set<String> cacheLoad = new HashSet<>();
    /**
     * 异步加载头像位图到ImageLoader内存缓存
     */
    private static void asyncLoadAvatarBitmapToCache(String url) {
        if (url == null || !isImageUriValid(url)) {
            return;
        }

        String key = getAvatarCacheKey(url);
        if(cacheLoad.contains(key)){
            return;
        }
        cacheLoad.add(key);
        ImageLoadingListener listener = new ImageLoadingListener() {
            @Override
            public void onLoadingStarted(String s, View view) {

            }

            @Override
            public void onLoadingFailed(String s, View view, FailReason failReason) {

            }

            @Override
            public void onLoadingComplete(String s, View view, Bitmap bitmap) {
                cacheLoad.remove(s);
            }

            @Override
            public void onLoadingCancelled(String s, View view) {

            }
        };
        ImageLoader.getInstance().loadImage(key,
                new ImageSize(DEFAULT_AVATAR_THUMB_SIZE, DEFAULT_AVATAR_THUMB_SIZE),
                avatarLoadOption, listener);
    }

    /**
     * 头像ImageLoader加载配置
     */
    private static DisplayImageOptions avatarLoadOption = createImageOptions();

    private static final DisplayImageOptions createImageOptions() {
        return new DisplayImageOptions.Builder()
                .cacheInMemory(true)
                .cacheOnDisk(true)
                .bitmapConfig(Bitmap.Config.RGB_565)
                .build();
    }
}
