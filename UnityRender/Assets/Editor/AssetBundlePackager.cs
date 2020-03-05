
using UnityEngine;
using System;
using UnityEditor;

/// <summary>
/// 打包机
/// </summary>
public class AssetBundlePackager {

    [MenuItem("Assets/资源打包")]
    static void BuildAllAssetBundles_pc()
    {
        BuildTarget targetPlatform = BuildTarget.StandaloneWindows64;
        BuildAssetBundleOptions assetBundleOptions = BuildAssetBundleOptions.None;
        string outputPath = Application.dataPath + "/MyAssets/";
        //string outputPath = Application.dataPath + "/StreamingAssets/WebGL";
        BuildPipeline.BuildAssetBundles(outputPath, assetBundleOptions, targetPlatform);
        //MyBuild();
    }

    [MenuItem("Assets/场景选择打包")]
    static void MyBuild()
    {
        var path2 = EditorUtility.OpenFilePanel("打开我们的UNITY场景", "", "unity");     //场景选择
        string[] paths = path2.Split('/');
        string MyScens = paths[paths.Length - 1];
        string MysecnsName = MyScens.Split('.')[0];
        int index = path2.IndexOf("Assets", StringComparison.Ordinal);
        string path =path2.Substring(index, path2.Length - index);
        Debug.Log(MysecnsName);
        // 需要打包的场景名字

        string[] levels = { path };        
        // 注意这里【区别】通常我们打包，第2个参数都是指定文件夹目录，在此方法中，此参数表示具体【打包后文件的名字】
        // 记得指定目标平台，不同平台的打包文件是不可以通用的。最后的BuildOptions要选择流格式
        BuildPipeline.BuildPlayer(levels, Application.dataPath + "/MyAssets/" + MysecnsName + ".unity3d", BuildTarget.StandaloneWindows64, BuildOptions.BuildAdditionalStreamedScenes);
        // 刷新，可以直接在Unity工程中看见打包后的文件
        AssetDatabase.Refresh();
    }
}
