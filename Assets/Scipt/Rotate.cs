using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    [SerializeField] private float _speed;

    private void Update() 
    {
        transform.rotation = Quaternion.AngleAxis(_speed * Time.deltaTime, Vector3.up) * transform.rotation;
    }
}
