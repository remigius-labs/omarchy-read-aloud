import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "remi.say"
  ipcTarget: "remi.say"

  readonly property string engineDir: setting("engineDir", Quickshell.env("HOME") + "/.local/share/omarchy-say")
  readonly property string sayBin: engineDir + "/say"
  readonly property string settingsPath: engineDir + "/settings.json"
  property string sayState: "idle"
  property string voice: "af_heart"
  property string speed: "1.1"
  property bool showAllVoices: false
  property string genderFilter: "f"
  property bool showKeys: false
  readonly property var langVoices: Model.allVoices.filter(function(v) { return v.charAt(0) === root.lang })
  readonly property var genderVoices: langVoices.filter(function(v) { return v.charAt(1) === root.genderFilter })
  // Collapsed: one voice. The current voice if it matches the toggle, else the best of that gender.
  readonly property string topVoice: {
    if (voice.charAt(1) === genderFilter && voice.charAt(0) === lang) return voice
    var best = Model.shortVoices[lang].filter(function(v) { return v.charAt(1) === root.genderFilter })
    return best.length > 0 ? best[0] : (genderVoices[0] || voice)
  }
  readonly property var shownVoices: showAllVoices ? genderVoices : [topVoice]
  readonly property string lang: voice.charAt(0)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Every trigger (this icon or a keybind) writes its state here, so the bar
  // shows the spinner no matter where reading was started.
  FileView {
    id: stateFile
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/claude-say.state"
    watchChanges: true
    printErrors: false
    onFileChanged: this.reload()
    onLoaded: root.sayState = stateFile.text().trim() || "idle"
    onLoadFailed: root.sayState = "idle"
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    printErrors: false
    onLoaded: {
      try {
        var cfg = JSON.parse(settingsFile.text())
        if (cfg.voice) root.voice = cfg.voice
        if (cfg.speed) root.speed = Model.speeds.filter(function(v) { return Number(v) === Number(cfg.speed) })[0] || "1.1"
      } catch (e) {}
    }
  }

  function save() {
    settingsFile.setText(JSON.stringify({ voice: root.voice, speed: Number(root.speed) }, null, 2) + "\n")
  }

  function pickVoice(id) {
    root.voice = id
    save()
    Quickshell.execDetached(["env", "SAY_VOICE=" + id, root.sayBin, "--start", Model.sample(id)])
  }

  function pickLanguage(code) {
    if (code !== root.lang) pickVoice(Model.shortVoices[code][0])
  }

  // Scriptable view state: omarchy-shell remi.say-view <function> <arg>
  IpcHandler {
    target: "remi.say-view"
    function voices(show: bool): void { root.showAllVoices = show }
    function gender(g: string): void { root.genderFilter = g === "m" ? "m" : "f" }
    function settings(show: bool): void { root.showKeys = show; if (show) root.showAllVoices = false }
  }

  onOpenedChanged: if (opened) { showAllVoices = false; genderFilter = root.voice.charAt(1); showKeys = false; settingsFile.reload() }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.sayState === "playing" ? "󰓛" : "󰆈"
    iconComponent: root.sayState === "loading" ? ring : null
    tooltipText: root.opened ? ""
        : root.sayState === "loading" ? "Getting ready · click to cancel"
        : root.sayState === "playing" ? "Stop reading" : "Read the clipboard aloud · right-click for voice"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggle()
      else Quickshell.execDetached([root.sayBin, "--clip"])
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: heroLeft.implicitHeight

        Column {
          anchors.right: parent.right
          anchors.top: parent.top
          spacing: Style.space(2)
          Text {
            anchors.right: parent.right
            text: "Kokoro 82M"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
          Text {
            anchors.right: parent.right
            text: "runs locally"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Column {
          id: heroLeft
          anchors.left: parent.left
          anchors.top: parent.top
          spacing: Style.space(2)
          Text {
            text: Model.voiceName(root.voice)
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            text: Model.language(root.lang).name + " · " + root.speed + "×"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Item {
          width: parent.width
          implicitHeight: genderToggle.implicitHeight

          PanelSectionHeader {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "VOICE"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: genderToggle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰊝"
              color: root.bar.foreground
              opacity: root.genderFilter === "m" ? 1.0 : 0.4
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              MouseArea { anchors.fill: parent; onClicked: root.genderFilter = "m" }
            }
            ToggleSwitch {
              anchors.verticalCenter: parent.verticalCenter
              checked: root.genderFilter === "f"
              cursorRing: false
              foreground: root.bar.foreground
              accent: root.bar.foreground
              onToggled: root.genderFilter = checked ? "m" : "f"
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰊜"
              color: root.bar.foreground
              opacity: root.genderFilter === "f" ? 1.0 : 0.4
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              MouseArea { anchors.fill: parent; onClicked: root.genderFilter = "f" }
            }
          }
        }
        Column {
          width: parent.width
          spacing: Style.space(8)
          Repeater {
            model: root.shownVoices
            Button {
              id: voiceRow
              required property var modelData
              width: parent.width
              text: Model.voiceName(modelData)
              leftAlign: true
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY
              bordered: true
              active: modelData === root.voice
              onClicked: root.pickVoice(modelData)

              Text {
                anchors.right: parent.right
                anchors.rightMargin: Style.spacing.controlPaddingX
                anchors.verticalCenter: parent.verticalCenter
                text: voiceRow.modelData.charAt(1) === "f" ? "󰊜" : "󰊝"
                color: root.bar.foreground
                opacity: 0.7
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
          Button {
            width: parent.width
            text: root.showAllVoices ? "Show less" : "All voices (" + root.genderVoices.length + ")"
            iconText: root.showAllVoices ? "󰅃" : "󰅀"
            iconSize: Style.font.title
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY
            bordered: false
            onClicked: root.showAllVoices = !root.showAllVoices
          }
        }

        Item {
          width: parent.width
          implicitHeight: gearButton.implicitHeight

          Button {
            id: gearButton
            width: parent.width
            text: root.showKeys ? "Hide settings" : "Settings · speed, language, keys"
            leftAlign: true
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY
            bordered: true
            active: root.showKeys
            onClicked: {
              root.showKeys = !root.showKeys
              if (root.showKeys) root.showAllVoices = false
            }

            Text {
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.controlPaddingX
              anchors.verticalCenter: parent.verticalCenter
              text: "󰒓"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
            }
          }
        }
        PanelSectionHeader {
          visible: root.showKeys
          text: "SPEED"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }
        Chips {
          visible: root.showKeys
          width: parent.width
          options: Model.speeds.map(function(v) { return { value: v, label: v + "×" } })
          value: root.speed
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          onPicked: function(v) { root.speed = v; root.save() }
        }

        PanelSectionHeader {
          visible: root.showKeys
          text: "LANGUAGE"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }
        Chips {
          visible: root.showKeys
          width: parent.width
          perRow: 5
          options: Model.languages.map(function(l) {
            return { value: l.value, label: l.label, tooltip: l.name }
          })
          value: root.lang
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          onPicked: function(v) { root.pickLanguage(v) }
        }

        PanelSectionHeader {
          visible: root.showKeys
          text: "KEYS"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }
        Column {
          visible: root.showKeys
          width: parent.width
          spacing: Style.space(8)
          Repeater {
            model: [
              { keys: ["AltGr", "Ctrl"], does: "Read / stop" }
            ]
            Item {
              required property var modelData
              width: parent.width
              implicitHeight: keyRow.implicitHeight
              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.does
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
              Row {
                id: keyRow
                anchors.right: parent.right
                spacing: Style.space(4)
                Repeater {
                  model: modelData.keys
                  Rectangle {
                    required property var modelData
                    implicitWidth: keyText.implicitWidth + Style.space(12)
                    implicitHeight: keyText.implicitHeight + Style.space(6)
                    radius: Style.space(3)
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.darker(root.bar.foreground, 1.8)
                    Text {
                      id: keyText
                      anchors.centerIn: parent
                      text: modelData
                      color: Qt.darker(root.bar.foreground, 1.2)
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }
            }
          }
        }

        PanelSectionHeader {
          visible: root.showKeys
          text: "MODEL"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }
        Chips {
          visible: root.showKeys
          width: parent.width
          perRow: 2
          options: [
            { value: "https://github.com/hexgrad/kokoro", label: "󰊤 GitHub", tooltip: "Kokoro on GitHub" },
            { value: "https://huggingface.co/hexgrad/Kokoro-82M", label: "🤗 Hugging Face", tooltip: "Kokoro-82M on Hugging Face" }
          ]
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          onPicked: function(url) { Qt.openUrlExternally(url); root.close() }
        }
      }
    }
  }

  // Drawn fresh every frame in a fixed spot; only the gap travels. Rotating a
  // glyph or a bitmap wobbles at fractional scaling.
  Component {
    id: ring
    Item {
      Canvas {
        id: arc
        property real angle: 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        width: 12
        height: 12
        onAngleChanged: requestPaint()
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          ctx.lineWidth = 1.6
          ctx.lineCap = "round"
          ctx.strokeStyle = button.foreground
          ctx.beginPath()
          ctx.arc(6, 6, 4.6, angle, angle + Math.PI * 1.5)
          ctx.stroke()
        }
        NumberAnimation on angle {
          from: 0
          to: Math.PI * 2
          duration: 900
          loops: Animation.Infinite
          running: true
        }
      }
    }
  }
}
