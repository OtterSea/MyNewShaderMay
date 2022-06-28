using UnityEngine;
using UnityEditor;

//有没有发现Unity官方的Material非常特别，他的Inspector界面与众不同？
//没错，Unity官方的Material由于定制内容太多，是进行了UI界面定制化的，我们也可以
//通过写这样的代码来定制我们的Material界面：

//CatlikeCodeing的教程系列的目的似乎就是创建一个最基础的着色器，所以每个篇章都值得学习

//在这里定义完我们的自定义GUI渲染代码后，还需要去对应的Shader代码里写入：(在Shader{}大括号里写入)
// CustomEditor "SumLightingShaderGUI"
//如果本脚本拥有命名空间，则上面的定义也需要用命名空间，用点隔开

public class SumLightingShaderGUI : ShaderGUI
{
    MaterialEditor editor;
    MaterialProperty[] properties;

    static GUIContent staticLabel = new GUIContent();
    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
    MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    //每次OnGUI也就是每次选中Material的时候，就会传递editor进来，无法避免，因为每个Material的界面
    //（数据）都可能是不一样的 界面放着不管 他也会不断执行OnGUI函数，界面每帧都可能不一样，没关系
    public override void OnGUI(
        MaterialEditor editor,
        MaterialProperty[] properties
    ) 
    {
        this.editor = editor;
        this.properties = properties;

        DoMain();
    }

    void DoMain()
    {
        //第二个参数是字体样式 这一行是定义一个Label，也就是一个标题，内容是Main..
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        //在 properties 中找到 对应名字的属性 他在数组的索引依据在Shader中的定义决定
        //但是用名字来查找比较好 ShaderGUI 包含Find.. 这个方法来查找
        // MaterialProperty mainTex = FindProperty("_MainTex", properties);
        //GUIContent 是一个简单的容器类，用来存放要绘制的UI
        // GUIContent albedoLabel = new GUIContent("Albedo");
        //后面的第二个参数是鼠标放置上去的提示
        // GUIContent albedoLabel = new GUIContent(mainTex.displayName, "仅支持RGB通道");
        //我们将贴图和贴图名lebel合成一行并绘制出来：
        // editor.TexturePropertySingleLine(albedoLabel, mainTex);

        //TexturePropertySingleLine是editor特定提供的处理贴图的GUI的，可容纳多个属性（最多三个
        //我们把 tint 颜色属性也融入：
        // MaterialProperty tint = FindProperty("_Tint", properties);
        // editor.TexturePropertySingleLine(albedoLabel, mainTex, tint);
        // editor.TextureScaleOffsetProperty(mainTex);

        //上面的方法，由于我们有好多其他贴图，我们完全可以独立出上面的步骤，缩短流程：
        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TexturePropertySingleLine(
            MakeLabel(mainTex, "Albedo(仅支持RGB)"), mainTex, FindProperty("_Tint")
        );

        //金属度和光滑度两个滑块
		DoMetallic();
		DoSmoothness();
        //绘制法线贴图的GUI
        DoNormals();


        //使用如下函数将 mainTex 的纹理平铺偏移的部分UI显示出来：
        editor.TextureScaleOffsetProperty(mainTex);
    }

	void DoMetallic () {
		// MaterialProperty map = FindProperty("_MetallicMap");
		// EditorGUI.BeginChangeCheck();
		// editor.TexturePropertySingleLine(
		// 	MakeLabel(map, "Metallic (R)"), map,
		// 	map.textureValue ? null : FindProperty("_Metallic")
		// );
		// if (EditorGUI.EndChangeCheck()) {
		// 	SetKeyword("_METALLIC_MAP", map.textureValue);
		// }
	}

	void DoSmoothness () {
		// SmoothnessSource source = SmoothnessSource.Uniform;
		// if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO")) {
		// 	source = SmoothnessSource.Albedo;
		// }
		// else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC")) {
		// 	source = SmoothnessSource.Metallic;
		// }
		MaterialProperty slider = FindProperty("_Smoothness");
        //使用这个代码：来增加缩进
		EditorGUI.indentLevel += 2;
        //将滑块显示出来
		editor.ShaderProperty(slider, MakeLabel(slider));
		EditorGUI.indentLevel += 1;
		// EditorGUI.BeginChangeCheck();
		// source = (SmoothnessSource)EditorGUILayout.EnumPopup(
		// 	MakeLabel("Source"), source
		// );
		// if (EditorGUI.EndChangeCheck()) {
		// 	RecordAction("Smoothness Source");
		// 	SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
		// 	SetKeyword(
		// 		"_SMOOTHNESS_METALLIC", source == SmoothnessSource.Metallic
		// 	);
		// }
		// EditorGUI.indentLevel -= 3;
	}

    void DoNormals()
    {
        MaterialProperty map = FindProperty("_NormalMap");
        //通过 textureValue 来检查是否有贴图数据，如果有就显示bumpscale，否则不显示
        editor.TexturePropertySingleLine(MakeLabel(map), map, 
            map.textureValue ? FindProperty("_BumpScale") : null);
    }


}
