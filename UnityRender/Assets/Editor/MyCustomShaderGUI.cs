using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace  GUIExtension
{
    enum Switchkeyword
    {
        UNIFORM,
        ALBEDO,
        METALLIC
    }
    enum RenderMode
    {
        Opaque=0, Cutout, Fade, Transparent
    }
    class RenderingSettings
    {
        public RenderQueue Queue;
        public string RenderType;
        public BlendMode SrcBlend, DstBlend;
        public bool ZWrite;

        public static RenderingSettings[] modes =
        {
            new RenderingSettings(){
                Queue = RenderQueue.Geometry, 
                RenderType = "", 
                SrcBlend = BlendMode.One, 
                DstBlend = BlendMode.Zero, 
                ZWrite = true
            },
            new RenderingSettings(){
                Queue = RenderQueue.AlphaTest, 
                RenderType = "TransparentCutout", 
                SrcBlend = BlendMode.One, 
                DstBlend = BlendMode.Zero, 
                ZWrite = true
            },
            new RenderingSettings(){ 
                Queue = RenderQueue.Transparent, 
                RenderType = "Transparent", 
                SrcBlend = BlendMode.SrcAlpha, 
                DstBlend = BlendMode.OneMinusSrcAlpha, 
                ZWrite = false
            },
            new RenderingSettings(){
                Queue = RenderQueue.Transparent, 
                RenderType = "Transparent", 
                SrcBlend = BlendMode.One, 
                DstBlend = BlendMode.OneMinusSrcAlpha, 
                ZWrite = false
            },
        };
    }

    public class MyCustomShaderGUI : ShaderGUI
    {
        Material targetMaterial;
        MaterialEditor MaterialEditor;
        MaterialProperty[] MaterialProperties;
        bool isShowCutoffAlpha;

        private string keyword_metallic = "_METALLIC_MAP";
        private string keyword_smoothness_albedo = "_SMOOTHNESS_ALBEDO";
        private string keyword_smoothness_metallic = "_SMOOTHNESS_METALLIC";
        private ColorPickerHDRConfig config = new ColorPickerHDRConfig(0, 99, 1 / 99f, 3f);
        
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            this.targetMaterial = materialEditor.target as Material;
            this.MaterialEditor = materialEditor;
            this.MaterialProperties = properties;
            DoMain();
            SecondaryShow();
        }

        #region tool methods

        void GUIStyleRichTextShow(string lable){
            GUIStyle style = EditorStyles.boldLabel;
            style.alignment = TextAnchor.MiddleCenter;
            style.richText = true;
            GUILayout.Label(lable, style);
        }
        GUIContent MakeMapGUIContent(MaterialProperty mp, string tooltip = null)
        {
            //displayName是shader内手写好的名字
            GUIContent content = new GUIContent(mp.displayName, mp.textureValue, tooltip);
            return content;
        }
        GUIContent MakeLabelGUIContent(MaterialProperty mp, string tooltip = null)
        {
            GUIContent content = new GUIContent(mp.displayName, tooltip);
            return content;
        }

        void MakeShaderSpecialPropertyShow(string propertyName,string tooltip = null)
        {
            MaterialProperty property = FindProperty(propertyName, MaterialProperties, true);
            MaterialEditor.ShaderProperty(property, MakeLabelGUIContent(property, tooltip));
        }
        MaterialProperty MakerMapWithScaleShow(string mapName, string scaleValue, bool inversShow = false, string toolTip = null)
        {
            MaterialProperty mapinfo = FindProperty(mapName, MaterialProperties, true);
            //没有纹理时不想显示bumpscale
            MaterialProperty bumpScale = null;
            if(inversShow){
                if(mapinfo.textureValue == null) bumpScale = FindProperty(scaleValue, MaterialProperties, true);
            }
            else{
                if(mapinfo.textureValue != null) bumpScale = FindProperty(scaleValue, MaterialProperties, true);
            }

            MaterialEditor.TexturePropertySingleLine(MakeMapGUIContent(mapinfo,toolTip), mapinfo, bumpScale);
            
            return mapinfo;
        }

        void SetKeyword(string keyword, bool enable)
        {
            if(enable)
                targetMaterial.EnableKeyword(keyword);
            else
                targetMaterial.DisableKeyword(keyword);
        }

        bool IsKeyEnable(string keyword)
        {
            return targetMaterial.IsKeywordEnabled(keyword);
        }

        void RecordAction (string label) {
            MaterialEditor.RegisterPropertyChangeUndo(label);
        }
        #endregion

        #region Main Map Show
        void DoMain()
        {
            SetRenderMode();
            MainMapLabel();
            var albedo = AlbedoPropertyShow();
            MetallicMapShow();
            //MetallicShow();
            //AlphaCutOffShow();
            SmoothnessShow();
            NormalShow();
            MaterialEditor.TextureScaleOffsetProperty(albedo);
        }

        void MainMapLabel()
        {
            GUIStyleRichTextShow("<color=Green>Main Map</color>");
        }

        MaterialProperty AlbedoPropertyShow()
        {
            return MakerMapWithScaleShow("_MainTex", "_Tint", false, "Main Texture");;
        }

        void NormalShow()
        {
            MakerMapWithScaleShow("_NormalMap", "_BumpScale");
        }

        void MetallicMapShow()
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty mp = MakerMapWithScaleShow("_MetallicMap", "_Metallic", true);
            if(EditorGUI.EndChangeCheck()){
                SetKeyword(keyword_metallic, mp.textureValue);
            }
        }
        //metallic smoothness
        //void MetallicShow()
        //{
        //    MakeShaderSpecialPropertyShow("_Metallic");
        //}
        void SmoothnessShow()
        {
            Switchkeyword source = Switchkeyword.UNIFORM;
            if (IsKeyEnable(keyword_smoothness_albedo))
                source = Switchkeyword.ALBEDO;

            if(IsKeyEnable(keyword_smoothness_metallic))
                source = Switchkeyword.METALLIC;
            
            //必须包围使用， 先缩进后恢复，不会影响后面的显示
            EditorGUI.indentLevel += 2;
            MakeShaderSpecialPropertyShow("_Smoothness");

            EditorGUI.indentLevel += 1;
            GUIContent gc = new GUIContent("Source");
            //在这里开始检查是否手动修改了下拉单元，然后设置对应的关键字
            EditorGUI.BeginChangeCheck();
            source = (Switchkeyword)EditorGUILayout.EnumPopup(gc, source);
            if (EditorGUI.EndChangeCheck())
            {
                //RecordAction("123124");//取消
                SetKeyword(keyword_smoothness_metallic, source == Switchkeyword.METALLIC);
                SetKeyword(keyword_smoothness_albedo, source == Switchkeyword.ALBEDO);
            }

            EditorGUI.indentLevel -= 3;
        }
        #endregion

        #region secondary map show
        void SecondaryShow()
        {
            SecondaryLabel();
            var detail = DetailTexShow();
            DetailNormalShow();
            OcclusionShow();
            DetailMaskShow();
            EmissionShow();
            MaterialEditor.TextureScaleOffsetProperty(detail);
        }
        void SecondaryLabel()
        {
            GUIStyleRichTextShow("<color=purple>Secondary Map</color>");
        }
        MaterialProperty DetailTexShow()
        {
            MaterialProperty detail = FindProperty("_DetailTex", MaterialProperties, true);
            MaterialEditor.TexturePropertySingleLine(MakeMapGUIContent(detail),detail);
            return detail;
        }
        void DetailNormalShow()
        {
            MakerMapWithScaleShow("_DetailNormalMap", "_DetailBumpScale");
        }

        void EmissionShow()
        {
            EditorGUI.BeginChangeCheck();

            MaterialProperty mapinfo = FindProperty("_EmissionMap", MaterialProperties, true);
            //没有纹理时不想显示bumpscale
            MaterialProperty emission = FindProperty("_Emission", MaterialProperties, true);
            MakeMapGUIContent(emission, null);
            this.MaterialEditor.TexturePropertyWithHDRColor
            (
                MakeMapGUIContent(mapinfo, "自发光纹理"),
                mapinfo,
                emission,
                config,
                false
            );
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_EMISSION_MAP", mapinfo.textureValue);
            }
        }

        void OcclusionShow()
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty mp = MakerMapWithScaleShow("_OcclusionMap", "_OcclusionStrength", false, "遮挡纹理");
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_OCCLUSION_MAP", mp.textureValue);
            }
        }

        void DetailMaskShow()
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty detail = FindProperty("_DetailMask", MaterialProperties, true);
            this.MaterialEditor.TexturePropertySingleLine(MakeMapGUIContent(detail, "遮罩纹理"), detail);
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_DETAIL_MASK", detail.textureValue);
            }
        }
        #endregion

        void AlphaCutOffShow()
        {
            MakeShaderSpecialPropertyShow("_AlphaCutoff");
        }

        void SetRenderMode()
        {
            RenderMode mode = RenderMode.Opaque;
            if (IsKeyEnable("_RENDERING_CUTOUT"))
            {
                mode = RenderMode.Cutout;
                isShowCutoffAlpha = true;
            }
            else if (IsKeyEnable("_RENDERING_FADE"))
            {
                mode = RenderMode.Fade;
            }
            else if (IsKeyEnable("_RENDERING_TRANSPARENT"))
            {
                mode = RenderMode.Transparent;
            }
            if(isShowCutoffAlpha) AlphaCutOffShow();
            EditorGUI.BeginChangeCheck();
            GUIContent gc = new GUIContent("RenderMode");
            mode = (RenderMode)EditorGUILayout.EnumPopup(gc, mode);
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_RENDERING_CUTOUT", mode == RenderMode.Cutout);
                SetKeyword("_RENDERING_FADE", mode == RenderMode.Fade);
                SetKeyword("_RENDERING_TRANSPARENT", mode == RenderMode.Transparent);
                //RenderQueue queue = mode == RenderMode.Opaque? RenderQueue.Geometry:RenderQueue.AlphaTest;
                //string renderType = mode == RenderMode.Opaque ? "" : "TransparentCutout";
                RenderingSettings settings = RenderingSettings.modes[(int)mode];
                targetMaterial.renderQueue = (int)settings.Queue;
                targetMaterial.SetOverrideTag("RenderType", settings.RenderType);
                targetMaterial.SetInt("_SrcBlend", (int)settings.SrcBlend);
                targetMaterial.SetInt("_DstBlend", (int)settings.DstBlend);
                targetMaterial.SetInt("_ZWrite", settings.ZWrite ? 1 : 0);
            }
            DoSimetransparentShadow(mode);
        }

        void DoSimetransparentShadow(RenderMode mode)
        {
            if (mode == RenderMode.Fade || mode == RenderMode.Transparent)
            {
                EditorGUI.BeginChangeCheck();
                bool enable = EditorGUILayout.Toggle
                (
                    new GUIContent("Semitransparent Shadow"), 
                    IsKeyEnable("_SEMITRANSPARENT_SHADOWS")
                );
                if(!enable) isShowCutoffAlpha = true;
                if (EditorGUI.EndChangeCheck())
                {
                    SetKeyword("_SEMITRANSPARENT_SHADOWS", enable);
                }
            }
        }
    }
}

