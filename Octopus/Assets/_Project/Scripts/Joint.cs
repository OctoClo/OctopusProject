using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Joint : MonoBehaviour
{
    public Vector3 Axis;
    public float MinAngle = -360;
    public float MaxAngle = 360;

    [HideInInspector]
    public Vector3 StartOffset;

    private void Awake()
    {
        StartOffset = transform.localPosition;
    }
}
