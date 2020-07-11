## UnityRender

翻译自catlikecoding.com的shader教程实践

##目录

* [1、Matrices](https://www.cnblogs.com/baolong-chen/p/12058419.html):创建一个Cube数组
支持缩放、位移、旋转
处理变换矩阵
简单的摄像机投影

* [2、Fundamentsl & syntax](https://www.cnblogs.com/baolong-chen/p/12122476.html)顶点变换. 
Color pixels. 
shader 属性. 
从顶点传数据至片元函数. 
查看编译后的shader代码.

* [3、Base Texture](https://www.cnblogs.com/baolong-chen/p/11747146.html)纹理基础
纹理采样
凹凸纹理计算方法

* [4、Unity Base Lighting](https://www.cnblogs.com/baolong-chen/p/12173995.html)把法线从模型空间变换到世界空间. 
使用方向光. 
计算漫反射和高光反射. 
Enforce energy conservation. 
渲染金属质感的物体. 
熟悉Unity的PBS算法. 

* [5、Unity Advance Lighting](https://www.cnblogs.com/baolong-chen/p/12245910.html)使用多个光源渲染
支持多光源类型
使用光照信息
计算顶点光照
了解球谐函数

* [6、Unity Advance Texture](https://www.cnblogs.com/baolong-chen/p/12267209.html)
* [7、Unity Shadow](https://www.cnblogs.com/baolong-chen/p/12057069.html)探索Unity中的阴影渲染
投射一个方向光阴影
接收一个方向光阴影
支持对聚光源和点光源阴影

* [8、Unity Reflection](https://www.cnblogs.com/baolong-chen/p/12347556.html)采样坏境
使用reflection probes探针
创建粗糙或光滑的镜面
完成box投影与立方体采样
混合两个探针

* [9&10、Shader gui extension](https://www.cnblogs.com/baolong-chen/p/12348691.html)自定义Shader GUI面板拓展
混合金属与非金属效果
非均匀平滑
表面自发光
把自身阴影烘焙进材质
增加细节纹理部分
支持更丰富的shader变体
一次编辑多个材质球


* [11、Unity Transparency](https://www.cnblogs.com/baolong-chen/p/12353282.html)剪纸镂空shader
渲染队列
半透明材质
合并反射和透明

* [12、Unity semitransparent](https://www.cnblogs.com/baolong-chen/p/12664143.html)支持镂空阴影
噪声
粗略的半透明阴影
镂空阴影和半透明阴影之间切换

* [13、Unity Deferred Shading](https://www.cnblogs.com/baolong-chen/p/12863511.html)探索延迟渲染
G-Buffer
HDR与LDR
Deffered反射

* [14、Unity Fog](https://www.cnblogs.com/baolong-chen/p/12902985.html)应用雾到游戏对象
基于距离或深度的雾
支持deferred fog

* [15、Unity Deferred Lights](https://www.cnblogs.com/baolong-chen/p/12914812.html)自定义灯光渲染
解码LDR颜色
增加独立Pass渲染光
支持方向光、点光源、聚光灯
手动采样阴影纹理

* [16、Static Lighting](https://www.cnblogs.com/baolong-chen/p/12970056.html)
* [17、Mixed Lighting](https://www.cnblogs.com/baolong-chen/p/13023331.html)只烘焙间接光
混合烘焙阴影和实时阴影
处理代码的变化和问题
支持消减光照（subtractivelighting）

* [18、Realtime GI & LOD](https://www.cnblogs.com/baolong-chen/p/13034495.html)支持实时全局光照 
用动画控制发光对GI的贡献 
使用光照探针代理体LPPV 
LOD组与GI结合 
LOD之间的淡入淡出

* [19、GPU Intance](https://www.cnblogs.com/baolong-chen/p/13040915.html)渲染大量球体-优化DrawCall
支持GPU-Instance
使用材质属性块
LOD-Groups支持GPU-Instance

* [20、Parallax shading](https://www.cnblogs.com/baolong-chen/p/13097087.html)
* [21、Flat and Wireframe shading](https://www.cnblogs.com/baolong-chen/p/13155566.html)
* [22、Hull And Domain Program](https://www.cnblogs.com/baolong-chen/p/13172655.html)

##PDF & Word下载

* [PDF](UnityShader翻译.pdf)
* [Word](UnityShader翻译.docx)
