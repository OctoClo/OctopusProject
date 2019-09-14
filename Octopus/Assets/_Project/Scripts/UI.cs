using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UI : MonoBehaviour
{
    [HideInInspector]
    public bool fadeCompleted = false;
    Animator animator;

    private void Start()
    {
        animator = GetComponent<Animator>();
    }

    public void LaunchFade()
    {
        animator.SetTrigger("Fade");
    }

    public void OnFadeComplete()
    {
        fadeCompleted = true;
    }
}
