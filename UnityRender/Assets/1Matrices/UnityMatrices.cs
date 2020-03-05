using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnityMatrices : MonoBehaviour
{
    public int generalCount;

    private float center;

    private Transform[] cubes;

    List<Transformation> transformations;

    private Matrix4x4 transformation;

    private void Awake()
    {
        transformations = new List<Transformation>();
        cubes = new Transform[generalCount * generalCount * generalCount];
        center = (generalCount - 1) * 0.5f;
    }

    // Use this for initialization
    void Start ()
    {
        InitCubeArray();
        gameObject.AddComponent<ScaleTransformation>();
        gameObject.AddComponent<RotationTransform>();
        gameObject.AddComponent<PositionTransformation>();
        gameObject.AddComponent<CameraTransformation>();
    }

    void InitCubeArray()
    {
        for (int i =0 , z = 0; z < generalCount; z++)
        {
            for (int y = 0; y < generalCount; y++)
            {
                for (int x = 0; x < generalCount; x++)
                {
                    cubes[i++] = CreateCubesPoint(x, y, z);
                }
            }
        }
    }

    Transform CreateCubesPoint(int x, int y, int z)
    {
        GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.transform.localScale = new Vector3(0.5f, 0.5f, 0.5f);
        cube.transform.localPosition = CreateCoordinate(x, y, z);
        cube.GetComponent<MeshRenderer>().material.color = CreateColor(x, y, z);
        return cube.transform;
    }

    Vector3 CreateCoordinate(int x, int y, int z)
    {
        return new Vector3(
            x - center,
            y - center,
            z - center
        );
    }

    Color CreateColor(int x, int y, int z)
    {
        return new Color(
            (float)x / center,
            (float)y / center,
            (float)z / center
        );
    }
    
    //可以实时查看效果
    private void Update()
    {
        //GetComponents<Transformation>(transformations);
        //for (int i = 0; i < cubes.Length; i++)
        //{
        //    cubes[i].localPosition = TransformPoint(cubes[i].localPosition);
        //}
        UpdateTransformation();

        for (int i =0 , z = 0; z < generalCount; z++)
        {
            for (int y = 0; y < generalCount; y++)
            {
                for (int x = 0; x < generalCount; x++)
                {
                    cubes[i++].localPosition = TransformPoint(x, y, z);
                }
            }
        }
    }
    void UpdateTransformation()
    {
        GetComponents<Transformation>(transformations);
        if(transformations.Count > 0)
        {
            transformation = transformations[0].Matrix;
            for (int i = 1; i < transformations.Count; i++)
            {
                transformation = transformations[i].Matrix * transformation;
            }
        }
    }

    Vector3 TransformPoint(int x, int y, int z)
    {
        Vector3 coordinates = CreateCoordinate(x, y, z);
        //for (int i = 0; i < transformations.Count; i++)
        //{
        //    coordinates = transformations[i].Apply(coordinates);
        //}
        return transformation.MultiplyPoint(coordinates);;
    }
}


public abstract class Transformation : MonoBehaviour
{
    public abstract Matrix4x4 Matrix { get; }
    public virtual Vector3 Apply(Vector3 point)
    {
        return Matrix.MultiplyPoint(point);
    }
}

public class PositionTransformation : Transformation
{
    public Vector3 position;

    public override Matrix4x4 Matrix {
        get {
            Matrix4x4 matrix = new Matrix4x4();
            matrix.SetRow(0, new Vector4(1f, 0f, 0f, position.x));
            matrix.SetRow(1, new Vector4(0f, 1f, 0f, position.y));
            matrix.SetRow(2, new Vector4(0f, 0f, 1f, position.z));
            matrix.SetRow(3, new Vector4(0f, 0f, 0f, 1f));
            return matrix;
        }
    }
}

public class ScaleTransformation : Transformation
{
    public Vector3 scale = new Vector3(1, 1, 1);

    public override Matrix4x4 Matrix {
        get {
            Matrix4x4 matrix = new Matrix4x4();
            matrix.SetRow(0, new Vector4(scale.x, 0f, 0f, 0f));
            matrix.SetRow(1, new Vector4(0f, scale.y, 0f, 0f));
            matrix.SetRow(2, new Vector4(0f, 0f, scale.z, 0f));
            matrix.SetRow(3, new Vector4(0f, 0f, 0f, 1f));
            return matrix;
        }
    }
    public override Vector3 Apply(Vector3 point)
    {
        return Matrix.MultiplyPoint3x4(point);
    }
}

public class RotationTransform : Transformation
{
    public Vector3 rotation = new Vector3(0,30,0);//每个分量表示角度
    public int rotDelta;

    public override Matrix4x4 Matrix {
        get {
            float radx = rotation.x * Mathf.Deg2Rad;
            float rady = rotation.y * Mathf.Deg2Rad;
            float radz = rotation.z * Mathf.Deg2Rad;

            float sinx = Mathf.Sin(radx);
            float cosx = Mathf.Cos(radx);
            float siny = Mathf.Sin(rady);
            float cosy = Mathf.Cos(rady);
            float sinz = Mathf.Sin(radz);
            float cosz = Mathf.Cos(radz);

            Matrix4x4 matrix = new Matrix4x4();
            matrix.SetColumn(0, new Vector4(
                 cosy * cosz,
                 cosx * sinz + sinx * siny * cosz,
                 sinx * sinz - cosx * siny * cosz,
                 0f
            ));
            matrix.SetColumn(1, new Vector4(
                 -cosy * sinz,
                 cosx * cosz - sinx * siny * sinz,
                 sinx * cosz + cosx * siny * sinz,
                 0f
            ));
            matrix.SetColumn(2, new Vector4(
                 siny,
                 -sinx * cosy,
                 cosx * cosy,
                 0
            ));
            matrix.SetColumn(3, new Vector4(0f,0f,0f,1f));
            return matrix;
        }
    }
    public override Vector3 Apply(Vector3 point)
    {
        return Matrix.MultiplyPoint3x4(point);
    } 


    private void Update()
    {
        //rotation = new Vector3(rotDelta, rotDelta, rotDelta);
    }
}

public class CameraTransformation : Transformation
{
    public float focalLenth = 1f;
    public override Matrix4x4 Matrix {
        get {
            Matrix4x4 matrix = new Matrix4x4();
            matrix.SetRow(0, new Vector4(focalLenth, 0f, 0f, 0f));
            matrix.SetRow(1, new Vector4(0f, focalLenth, 0f, 0f));
            matrix.SetRow(2, new Vector4(0f, 0f, 0f, 0f));
            matrix.SetRow(3, new Vector4(0f, 0f, 1f, 0f));
            return matrix;
        }
    }
}