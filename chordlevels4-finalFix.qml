//=======================================================================================================
//  Chord Level Filter for MuseScore 4.x
//  This script was inspired by worldwideweary's "Chord Level Selector". 
//  Most portion of the main function were re-written (except for the get chords section), 
//  some bugs fixed (see below) and other funcionalities were added; specifically, 
//  the options "Copy levels", and "Crop to levels". The UI was also redesigned to contain the 
//  new functionalities and level boxes where regrouped into a single vertical column, 
//  now with the "bottom note" on the bottom. 
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=======================================================================================================
import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
    title: "Filter Chord Levels"
    version: "1.1"
    description: "Choose the notes levels you wish to filter/select or apply other operations to within a range selection."
    categoryCode: "Editing tools"
    thumbnailName: ""   
    pluginType: "dialog"    
    width:  500
    height: 225


    function displayMessageDlg(msg) {
        ctrlMessageDialog.text = qsTr(msg);
        ctrlMessageDialog.visible = true;
    }

    function selectLevels(move, deleteDesired, copy, crop) {        
       
        ////////////// GET SELECTION //////////////////
        //////////////////////////////////////////////
        var cursor = curScore.newCursor();
        cursor.rewind(1);
        var startTick = cursor.tick;
        var startStaff;
        var endStaff;
        var endTick;       

        startStaff = cursor.staffIdx;
        cursor.rewind(2);
        if (cursor.tick == 0) {            
            endTick = curScore.lastSegment.tick + 1;
        } else {
            endTick = cursor.tick;
        }

        endStaff = cursor.staffIdx;
        ///////////////////////////////////////////
        ///////////////////////////////////////////        
        var operationPerformed = false;
        curScore.startCmd(); // Start collecting undo info.        
        ////////////////////  GET CHORDS //////////////////////////
        //////////////////////////////////////////////////////////
        var chords = new Array();
        var maxChordLength=0
        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(1); // sets voice to 0
                cursor.voice = voice; //voice has to be set after goTo
                cursor.staffIdx = staff;
                
                while (cursor.segment && (cursor.tick < endTick)) {
                    if (cursor.element && cursor.element.type == Element.CHORD) {
                        var graceChords = cursor.element.graceNotes;
                        for (var i = 0; i < graceChords.length; i++) {
                            chords.push(graceChords[i]);
                        }

                        // the chord of the notes...
                        chords.push(cursor.element);

                        if (cursor.element.notes.length > maxChordLength ){
                            maxChordLength=cursor.element.notes.length
                        }
                    }
                    cursor.next();
                }
            }
        }  
        ///////////////////////////////////////////
        ///////////////////////////////////////////

        
        if (!chords.length) {
            displayMessageDlg(qsTr("No valid range selection on current score! Tsk Tsk."));
            return;
        }

        var levels = new Array();      

        if (ctrlCheckBoxLevel7.checked) { levels.push(7) }
        if (ctrlCheckBoxLevel6.checked) { levels.push(6) }
        if (ctrlCheckBoxLevel5.checked) { levels.push(5) }
        if (ctrlCheckBoxLevel4.checked) { levels.push(4) }
        if (ctrlCheckBoxLevel3.checked) { levels.push(3) }
        if (ctrlCheckBoxLevel2.checked) { levels.push(2) }
        if (ctrlCheckBoxLevel1.checked) { levels.push(1) }       
        
        
        if (!levels.length && !ctrlCheckBoxTopLevel.checked || levels[levels.length-1] > maxChordLength  ) {
            displayMessageDlg(qsTr("No levels(s) checked! Select the level(s) that match your chord stack sizes."));
            return;
        }       

        // Method: will clear the range selection and begin adding one at a time the notes that correlate with user-checked levels
        curScore.selection.clear();

        ////////////// SELECT DESIRED NOTE LEVELS  //////////////////////
        ////////////////////////////////////////////////////////////////
        var emptyChordPotential = false;
        for (var c = 0; c < chords.length; c++) { 
            var topNote= chords[c].notes[chords[c].notes.length - 1].pitch
            for (var n = 0; n < chords[c].notes.length; n++) {            
                if ((crop || copy) && !levels.includes(n+1) ){                       
                    curScore.selection.select(chords[c].notes[n], true)
                }                                            
                if (!crop & !copy && levels.includes(n+1) ){
                    curScore.selection.select(chords[c].notes[n], true);                    
                }
            }            
            if ((crop || copy) && ctrlCheckBoxTopLevel.checked ) {
                curScore.selection.deselect(chords[c].notes[chords[c].notes.length - 1])
            }
            if (!crop && !copy && ctrlCheckBoxTopLevel.checked) {
                curScore.selection.select(chords[c].notes[chords[c].notes.length - 1], true)
            }            
        } /// end all chords iteration


        if (deleteDesired || copy || crop) { 
            cmd("delete")
        }
        
        // Switch voice of remaining selection if Revoice
        if (move) {
            var cmdVoiceIndex = ctrlComboBoxVoice.currentIndex + 1;            
            cmd("voice-" + cmdVoiceIndex);            
        }

        curScore.endCmd(); // Finish off the undo record.        
        
        if (copy) {
            curScore.selection.selectRange(startTick, endTick, startStaff, endStaff+1);
            cmd("copy")
            cmd("undo")
        }

        operationPerformed = true;
        return operationPerformed;
    }


    onRun: {     

        if (typeof curScore === 'undefined') {
            var msg = "Chord Levels exiting without processing - no current score!";            
            displayMessageDlg(msg);
            quit();
        }
    }

    Rectangle {
        property alias mouseArea: mouseArea
        property alias btnCopy: btnCopy
        property alias btnCrop: btnCrop
        property alias btnDeleteLevels: btnDeleteLevels
        property alias btnRevoiceLevels: btnRevoiceLevels
        property alias btnClose: btnClose
        property alias ctrlHintLabel: ctrlHintLabel
        property alias ctrlMessageDialog: ctrlMessageDialog

        width: 600 // added 200 (from 400)
        height: 250
        color: "grey"

        MessageDialog {
            id: ctrlMessageDialog
            icon: StandardIcon.Information
            title: "Chord Levels Message"
            text: "Welcome to Chord Levels!"
            visible: false
            onAccepted: {
                visible = false;
            }
        }

        MouseArea {
            id: mouseArea
            anchors.rightMargin: 0
            anchors.bottomMargin: 0
            anchors.leftMargin: 0
            anchors.topMargin: 0
            anchors.fill: parent

            Text {
                id: ctrlStackRangeLabel
                x: 180 //  25
                y: 15
                width: 100
                text: "Levels:"
            }

            Column {
                x: 180////80 
                y: 35 

            // Column {
            //     x: 175 // origin 125
            //     y: 15
                CheckBox {
                    id: ctrlCheckBoxTopLevel
                    text: "Top" // 8
                }
                CheckBox {
                    id: ctrlCheckBoxLevel7
                    text: qsTr("7")
                }
                CheckBox {
                    id: ctrlCheckBoxLevel6
                    text: qsTr("6")
                }
                CheckBox {
                    id: ctrlCheckBoxLevel5
                    text: qsTr("5")
                }
                CheckBox {
                    id: ctrlCheckBoxLevel4
                    text: qsTr("4")
                }
                CheckBox {
                    id: ctrlCheckBoxLevel3
                    text: qsTr("3")
                }
                CheckBox {
                    id: ctrlCheckBoxLevel2
                    text: qsTr("2")
                }
                CheckBox {
                    id: ctrlCheckBoxLevel1
                    text: qsTr("Bottom") // 1
                }
            // }
            }

            Text {
                id: ctrlVoicesLabel
                x:  435 // orig 292
                y:  40
                width: 100
                text: "Voice:"
            }

            ComboBox {
                id: ctrlComboBoxVoice
                width: 55
                currentIndex: 1
                x: 435
                y: 60
                model: ListModel {
                    id: cbVoiceItems
                    ListElement { text: "1"; color: "Blue" }
                    ListElement { text: "2"; color: "Green" }
                    ListElement { text: "3"; color: "Brown" }
                    ListElement { text: "4"; color: "Purple" }
                }
            }

            Button {
                id: btnCopy
                x: 280
                y: 175
                width: 150
                height: 35
                text: qsTr("Copy")
                onClicked: {
                    if (selectLevels(false, false, true, false)) {
                        quit();
                    }
                }
            }

            Button {
                id: btnCrop
                x: 280
                y: 135
                width: 150
                height: 35
                text: qsTr("Crop To levels")
                onClicked: {
                    if (selectLevels(false, false, false, true)) {
                        quit();
                    }
                }
            }

            Button {
                id: btnDeleteLevels
                x: 280
                y: 95
                width: 150
                height: 35
                text: qsTr("Delete")
                onClicked: {
                    if (selectLevels(false, true, false, false)) {
                        quit();
                    }
                }
            }

            Button {
                id: btnRevoiceLevels
                x: 280
                y: 55
                width: 150
                height: 35
                text: qsTr("Change to voice:")
                onClicked: {
                    if (selectLevels(true, false, false, false)) {
                        quit();
                    }
                }
            }

            Button {
                id: btnSelectLevels
                x: 280
                y: 15
                width: 150
                height: 35
                text: qsTr("Select")
                onClicked: {
                    if (selectLevels(false, false, false, false)) {
                        quit();
                    }
                }
            }


            Button {
                id: btnClose
                x: 20  ////50  
                y: 170
                width: 125 
                height: 35
                text: qsTr("Close")                
                onClicked: {
                    console.log("Chord Levels closed.");
                    quit();
                }
            }

            Text {
                id: ctrlHintLabel
                x: 20
                y: 30 //  100
                width: 100 ////   250
                text: qsTr("Check the levels you want to delete, change voice, crop, copy, or select for further operations.")
                font.italic: true
                color: "white"
                wrapMode: Text.WordWrap
                font.pointSize: 9
            }

        }

    }
}
