package unischedule.ui.components;

import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import javax.swing.table.AbstractTableModel;
import unischedule.model.Lesson;

public class ScheduleTableModel extends AbstractTableModel {

    public ScheduleTableModel(List<unischedule.model.Lesson> initialLessons) {
        if (initialLessons != null) {
            setLessons(initialLessons);
        }
    }

    private final String[] columnNames = {
        "День недели",
        "Время",
        "Тип",
        "Предмет",
        "Преподаватель",
        "Группа",
        "Аудитория",
        "Комментарий",
    };

    private final List<Object> displayItems = new ArrayList<>();

    public void setLessons(List<Lesson> lessons) {
        displayItems.clear();
        if (lessons == null || lessons.isEmpty()) {
            fireTableDataChanged();
            return;
        }

        lessons.sort((l1, l2) -> {
            int day1 = l1.getDate().getDayOfWeek().getValue();
            int day2 = l2.getDate().getDayOfWeek().getValue();
            if (day1 != day2) return Integer.compare(day1, day2);

            return l1
                .getTimeSlot()
                .getFirstStartTime()
                .compareTo(l2.getTimeSlot().getFirstStartTime());
        });

        java.time.LocalDate lastDate = null;
        java.time.format.DateTimeFormatter dayFormatter =
            java.time.format.DateTimeFormatter.ofPattern(
                "EEEE",
                new java.util.Locale("ru")
            );

        for (Lesson l : lessons) {
            if (lastDate == null || !l.getDate().equals(lastDate)) {
                displayItems.add(
                    l.getDate().format(dayFormatter).toUpperCase()
                );
                lastDate = l.getDate();
            }
            displayItems.add(l);
        }
        fireTableDataChanged();
    }

    @Override
    public Object getValueAt(int row, int col) {
        Object item = displayItems.get(row);

        if (item instanceof String) {
            return col == 0 ? item : "";
        }

        Lesson l = (Lesson) item;
        switch (col) {
            case 0:
                return "";
            case 1:
                return l.getTimeSlot().getFormattedRange();
            case 2:
                return l.getLessonType();
            case 3:
                return l.getSubject();
            case 4:
                return l.getTeacher().getName();
            case 5:
                return l.getGroup().getName();
            case 6:
                return l.getClassroom().getName();
            case 7:
                return l.getComment();
            default:
                return null;
        }
    }

    public boolean isHeaderRow(int row) {
        return displayItems.get(row) instanceof String;
    }

    @Override
    public int getRowCount() {
        return displayItems.size();
    }

    @Override
    public int getColumnCount() {
        return columnNames.length;
    }

    @Override
    public String getColumnName(int col) {
        return columnNames[col];
    }

    public unischedule.model.Lesson getLessonAt(int row) {
        if (row < 0 || row >= displayItems.size()) return null;

        Object item = displayItems.get(row);
        if (item instanceof unischedule.model.Lesson) {
            return (unischedule.model.Lesson) item;
        }
        return null;
    }
}
