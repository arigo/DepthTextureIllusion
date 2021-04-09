using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class CaptureFarAway : MonoBehaviour
{
    public int resolution;
    public RenderTexture rtColor, rtDepth;


    private void Start()
    {
        rtColor = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.Default);
        //rtColor.antiAliasing = 8;
        rtColor.wrapMode = TextureWrapMode.Clamp;
        rtColor.filterMode = FilterMode.Point;

        rtDepth = new RenderTexture(resolution, resolution, 24, RenderTextureFormat.Depth);
        //rtDepth.antiAliasing = 8;
        rtDepth.wrapMode = TextureWrapMode.Clamp;
        rtDepth.filterMode = FilterMode.Point;

        var camera = GetComponent<Camera>();
        camera.SetTargetBuffers(rtColor.colorBuffer, rtDepth.depthBuffer);
        camera.Render();

        //rtColor.ResolveAntiAliasedSurface();

        Shader.SetGlobalTexture("_FarAwayPlanarColor", rtColor);
        Shader.SetGlobalTexture("_FarAwayPlanarDepth", rtDepth);
    }
}
