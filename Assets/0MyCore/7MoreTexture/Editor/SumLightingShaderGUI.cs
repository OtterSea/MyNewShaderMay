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
    public override void OnGUI(
        MaterialEditor editor,
        MaterialProperty[] properties
    ) 
    {
        DoMain();
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
    }
}
