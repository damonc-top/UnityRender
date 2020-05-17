using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DeferredFogRender : MonoBehaviour 
{
    public  Shader   fogShader;
    private Material fogMate;
    private Camera   deferredCamera;
    private Rect     rectArea;
    private Vector3[] corners;
    private Vector4[] frustumCorners;

    private void Start()
    {
        fogMate = new Material(fogShader);
        deferredCamera = GetComponent<Camera>();
        rectArea = new Rect(0,0,1,1);
        corners = new Vector3[4];
        frustumCorners = new Vector4[4];
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        deferredCamera.CalculateFrustumCorners
        (
            rectArea,
            deferredCamera.farClipPlane,
            deferredCamera.stereoActiveEye,
            corners //camera corners 
        );
        //corners vectex index: b-l, u-l, u-r, b-r
        //shader vectex index : b-l, b-r, u-l, u-r
        frustumCorners[0] = corners[0];
        frustumCorners[1] = corners[3];
        frustumCorners[2] = corners[1];
        frustumCorners[3] = corners[2];
        //fogMate.SetMatrix
        fogMate.SetVectorArray("_FustumCorners", frustumCorners);
        Graphics.Blit(source, destination, fogMate);
    }
}