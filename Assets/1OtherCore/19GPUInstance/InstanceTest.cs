using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class InstanceTest : MonoBehaviour
{
    public GameObject prefab;

    public int instances = 5000;

    public float radius = 50f;

    private void Start()
    {
        for(int i = 0; i < instances; i++)
        {
            Transform t = Instantiate(prefab).transform;
            t.localPosition = Random.insideUnitSphere * radius;
            t.localPosition = new Vector3(t.localPosition.x, 0, t.localPosition.z);
            t.SetParent(transform);
        }
    }
}
