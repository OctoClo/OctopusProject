using UnityEngine;
using UnityEditor;

public class LightingShaderGUI : ShaderGUI
{
    enum SmoothnessSource
    {
        Uniform, Albedo, Metallic
    }

    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;

    static GUIContent staticLabel = new GUIContent();

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
    {
        target = materialEditor.target as Material;
        editor = materialEditor;
        properties = materialProperties;
        MainGUI();
        SecondaryGUI();
    }

    private void MainGUI()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TexturePropertySingleLine(MakeLabel(mainTex), mainTex, FindProperty("_Tint"));

        MetallicGUI();
        SmoothnessGUI();
        NormalsGUI(false);
        EmissionGUI();

        editor.TextureScaleOffsetProperty(mainTex);
    }

    void SecondaryGUI()
    {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex");
        editor.TexturePropertySingleLine(MakeLabel(detailTex), detailTex);
        NormalsGUI(true);
        editor.TextureScaleOffsetProperty(detailTex);
    }

    private void NormalsGUI(bool details)
    {
        MaterialProperty normals = FindProperty(details ? "_DetailNormalMap" : "_NormalMap");
        editor.TexturePropertySingleLine(MakeLabel(normals), normals, normals.textureValue ? FindProperty(details ? "_DetailBumpScale" : "_BumpScale") : null);
    }

    private void MetallicGUI()
    {
        MaterialProperty map = FindProperty("_MetallicMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(map, "Metallic (R)"), map, map.textureValue ? null : FindProperty("_Metallic"));

        if (EditorGUI.EndChangeCheck())
            SetKeyword("_METALLIC_MAP", map.textureValue);
    }

    private void SmoothnessGUI()
    {
        SmoothnessSource source = SmoothnessSource.Uniform;
        if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO"))
            source = SmoothnessSource.Albedo;
        else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC"))
            source = SmoothnessSource.Metallic;

        MaterialProperty slider = FindProperty("_Smoothness");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel += 1;
        EditorGUI.BeginChangeCheck();
        source = (SmoothnessSource)EditorGUILayout.EnumPopup(MakeLabel("Source"), source);
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Smoothness Source");
            SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
            SetKeyword("_SMOOTHNESS_METALLIC", source == SmoothnessSource.Metallic);
        }
        EditorGUI.indentLevel -= 3;
    }

    private void EmissionGUI()
    {
        MaterialProperty map = FindProperty("_EmissionMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertyWithHDRColor(MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission"), false);

        if (EditorGUI.EndChangeCheck())
            SetKeyword("_EMISSION_MAP", map.textureValue);
    }

    void SetKeyword(string keyword, bool state)
    {
        if (state)
            target.EnableKeyword(keyword);
        else
            target.DisableKeyword(keyword);
    }

    private MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    static GUIContent MakeLabel(string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    bool IsKeywordEnabled(string keyword)
    {
        return target.IsKeywordEnabled(keyword);
    }

    void RecordAction(string label)
    {
        editor.RegisterPropertyChangeUndo(label);
    }
}
