package unischedule.ui.components;

import unischedule.model.Lesson;
import javax.swing.table.AbstractTableModel;
import java.util.List;

/**
 * Кастомная модель таблицы. 
 * Она "знает" о списке занятий и умеет правильно отображать их поля.
 */
public class ScheduleTableModel extends AbstractTableModel {
    
    // Заголовки колонок
    private final String[] columnNames = {
        "Тип", "Предмет", "Преподаватель", "Группа", "Аудитория", "Время"
    };
    
    private List<Lesson> lessons;

    public ScheduleTableModel(List<Lesson> lessons) {
        this.lessons = lessons;
    }

    // Обновление данных в модели
    public void setLessons(List<Lesson> lessons) {
        this.lessons = lessons;
        fireTableDataChanged(); // Уведомляем таблицу, что данные изменились
    }

    @Override
    public int getRowCount() {
        return lessons.size();
    }

    @Override
    public int getColumnCount() {
        return columnNames.length;
    }

    @Override
    public String getColumnName(int column) {
        return columnNames[column];
    }

    @Override
    public Object getValueAt(int rowIndex, int columnIndex) {
        Lesson lesson = lessons.get(rowIndex);
        
        // Здесь используется полиморфизм (getLessonType) 
        // и инкапсуляция (геттеры сущностей)
        switch (columnIndex) {
            case 0: return lesson.getLessonType();
            case 1: return lesson.getSubject();
            case 2: return lesson.getTeacher().getName();
            case 3: return lesson.getGroup().getName();
            case 4: return lesson.getClassroom().getName();
            case 5: return lesson.getTimeSlot().toString();
            default: return null;
        }
    }
}