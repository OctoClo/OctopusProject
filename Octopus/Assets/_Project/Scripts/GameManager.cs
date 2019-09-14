using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    [Header("References")]
    public UI UI;
    public GameObject Target;
    public GameObject Tentacle;

    bool waitForUIFade = true;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            // Quit game
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
         Application.Quit();
#endif
        }

        if (waitForUIFade)
        {
            if (UI.fadeCompleted)
            {
                // Launch game
                Target.SetActive(true);
                Tentacle.SetActive(true);

                waitForUIFade = false;
            }
            else
            {
                if (Input.anyKeyDown)
                    UI.LaunchFade();
            }
        }
    }
}
