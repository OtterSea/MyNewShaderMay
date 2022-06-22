using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//显示出切线空间

public class TangentSpaceVisualizer : MonoBehaviour
{
    public float offset = 0f;
    public float scale = 0.1f;


    private void OnDrawGizmos()
    {
        MeshFilter filter = this.GetComponent<MeshFilter>();
        if(filter)
        {
            Mesh mesh = filter.sharedMesh;
            if(mesh)
            {
                ShowTangentSpace(mesh);
            }
        }
    }

    void ShowTangentSpace(Mesh mesh)
    {
        Vector3[] vertices = mesh.vertices;     //获取所有顶点
        Vector3[] normals = mesh.normals;       //获取所有法线
        Vector4[] tangents = mesh.tangents;     //获取所有切线
        for(int i = 0; i < vertices.Length; i++)
        {
            //此函数让法线、切线、副切线可视化
            ShowTangentSpace(
                transform.TransformPoint(vertices[i]),
                transform.TransformDirection(normals[i]),
                transform.TransformDirection(tangents[i]),
                tangents[i].w
            );
        }
    }

    void ShowTangentSpace(Vector3 vertex, Vector3 normal, Vector3 tangent, float binormalSign)
    {
        vertex = vertex + normal*offset;

        //绿色表示法线
        Gizmos.color = Color.green;
        Gizmos.DrawLine(vertex, vertex + normal * scale);

        //红色表示切线
        Gizmos.color = Color.red;
        Gizmos.DrawLine(vertex, vertex + tangent * scale);

        //蓝色表示副切线 tangent 是一个4D向量，他的 w 分量代表了副切线的正负
        //因此将法线和切线进行叉积后，再用 sign 来表示副切线的方向 （正负方向） 即可
        Vector3 binormal = Vector3.Cross(normal, tangent) * binormalSign;
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(vertex, vertex + binormal * scale);
    }
}