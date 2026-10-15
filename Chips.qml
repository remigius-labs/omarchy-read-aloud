import QtQuick
import qs.Commons
import qs.Ui

// A pick-one grid whose chips share the full width evenly.
Grid {
  id: chips
  property var options: []
  property string value: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property int perRow: options.length
  signal picked(string value)

  columns: perRow
  spacing: Style.space(8)

  Repeater {
    model: chips.options
    Button {
      required property var modelData
      width: (chips.width - chips.spacing * (chips.perRow - 1)) / chips.perRow
      text: modelData.label
      tooltipText: modelData.tooltip || ""
      fontSize: Style.font.bodySmall
      foreground: chips.foreground
      fontFamily: chips.fontFamily
      verticalPadding: Style.spacing.controlPaddingY
      bordered: true
      selected: modelData.value === chips.value
      onClicked: chips.picked(modelData.value)
    }
  }
}
