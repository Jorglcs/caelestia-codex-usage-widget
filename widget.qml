    Rectangle {
        id: codexUsage
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        radius: width / 2
        color: Colours.tPalette.m3surfaceContainer
        property var limits: ({})

        function details(window, label) {
            if (!window || window.usedPercent === undefined)
                return label + ": indisponível";
            let reset = window.resetsAt ? new Date(window.resetsAt * 1000).toLocaleString(Qt.locale(), "dd/MM HH:mm") : "indisponível";
            return label + ": " + Math.round(window.usedPercent) + "% usado\nRenova: " + reset;
        }

        Canvas {
            id: usageRing
            anchors.fill: parent
            property color trackColor: Colours.palette.m3surfaceVariant
            property color progressColor: Colours.palette.m3primary
            onTrackColorChanged: requestPaint()
            onProgressColorChanged: requestPaint()
            Connections {
                target: codexUsage
                function onLimitsChanged() { usageRing.requestPaint(); }
            }
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const lineWidth = Math.max(3, width * 0.07);
                const radius = (Math.min(width, height) - lineWidth * 2) / 2;
                const cx = width / 2;
                const cy = height / 2;
                ctx.lineWidth = lineWidth;
                ctx.lineCap = "round";
                ctx.strokeStyle = trackColor;
                ctx.beginPath();
                ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                ctx.stroke();
                const primary = codexUsage.limits.primary;
                if (primary && typeof primary.usedPercent === "number") {
                    const progress = Math.max(0, Math.min(100, primary.usedPercent)) / 100;
                    if (progress > 0) {
                        ctx.strokeStyle = progressColor;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * progress);
                        ctx.stroke();
                    }
                }
            }
        }

        Image {
            anchors.centerIn: parent
            width: parent.width * 0.55
            height: width
            sourceSize.width: Math.ceil(width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1))
            sourceSize.height: Math.ceil(height * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1))
            source: "file:///usr/share/icons/Papirus/24x24/panel/indicator-chatgpt.svg"
            fillMode: Image.PreserveAspectFit
        }

        MouseArea { id: codexMouse; anchors.fill: parent; hoverEnabled: true }
        Controls.ToolTip {
            visible: codexMouse.containsMouse
            delay: 300
            padding: 12
            background: Rectangle {
                color: Colours.palette.m3surfaceContainerHigh
                radius: 12
            }
            contentItem: Column {
                spacing: 10
                UsageDetails { window: codexUsage.limits.primary; label: "5 horas" }
                UsageDetails { window: codexUsage.limits.secondary; label: "Semana" }
            }
        }

        component UsageDetails: Column {
            required property var window
            required property string label
            spacing: 4
            width: 170
            Controls.Label { text: codexUsage.details(parent.window, parent.label) }
            Rectangle {
                width: parent.width
                height: 5
                radius: height / 2
                color: Colours.palette.m3surfaceVariant
                visible: parent.window && typeof parent.window.usedPercent === "number"
                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(100, parent.parent.window?.usedPercent ?? 0)) / 100
                    radius: height / 2
                    color: Colours.palette.m3primary
                }
            }
        }

        Process {
            id: limitsProcess
            command: ["python3", Quickshell.env("HOME") + "/.local/bin/codex-limits-widget.py"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try { codexUsage.limits = JSON.parse(text); } catch (e) { codexUsage.limits = {}; }
                }
            }
        }
        Timer { interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!limitsProcess.running) limitsProcess.running = true }
    }

