package unischedule.logic;

import unischedule.model.*;
import java.util.ArrayList;
import java.util.List;
import java.time.LocalDate;
import java.util.stream.Collectors;
import java.util.Comparator;

public class ScheduleManager {
    private final List<Lesson> lessons = new ArrayList<>();
    private final List<Teacher> teachers = new ArrayList<>();
    private final List<StudentGroup> groups = new ArrayList<>();
    private final List<Classroom> classrooms = new ArrayList<>();

    public void addTeacher(Teacher t) { teachers.add(t); }
    
    public void addGroup(StudentGroup g) throws Exception {
        for (StudentGroup existing : groups) {
            if (existing.getName().equalsIgnoreCase(g.getName())) {
                throw new Exception("Группа '" + g.getName() + "' уже существует!");
            }
        }
        groups.add(g);
    }
    
    public void addClassroom(Classroom c) throws Exception {
        for (Classroom existing : classrooms) {
            if (existing.getName().equalsIgnoreCase(c.getName())) {
                throw new Exception("Аудитория '" + c.getName() + "' уже добавлена!");
            }
        }
        classrooms.add(c);
    }

    public List<Teacher> getTeachers() { return teachers; }
    public List<StudentGroup> getGroups() { return groups; }
    public List<Classroom> getClassrooms() { return classrooms; }
    public List<Lesson> getLessons() { return lessons; }

    public void addLesson(Lesson newLesson) throws ConflictException {
        checkConflict(newLesson, -1);
        lessons.add(newLesson);
    }
    
    public void updateLesson(int index, Lesson newLesson) throws ConflictException {
        if (index >= 0 && index < lessons.size()) {
            checkConflict(newLesson, index); 
            lessons.set(index, newLesson);
        }
    }
    
    private void checkConflict(Lesson newLesson, int ignoreIndex) throws ConflictException {
        List<String> newTimes = newLesson.getTimeSlot().getStartTimes();
    
        for (int i = 0; i < lessons.size(); i++) {
            if (i == ignoreIndex) continue;
    
            Lesson existing = lessons.get(i);
            if (existing.getDate().equals(newLesson.getDate())) {
                List<String> existingTimes = existing.getTimeSlot().getStartTimes();
                
                boolean hasOverlap = newTimes.stream().anyMatch(existingTimes::contains);
    
                if (hasOverlap) {
                    if (existing.getTeacher().equals(newLesson.getTeacher())) 
                        throw new ConflictException("Преподаватель " + existing.getTeacher() + " уже занят в эти часы!");
                    
                    if (existing.getClassroom().equals(newLesson.getClassroom())) 
                        throw new ConflictException("Аудитория " + existing.getClassroom() + " занята!");
                    
                    if (existing.getGroup().equals(newLesson.getGroup())) 
                        throw new ConflictException("У группы " + existing.getGroup() + " уже идет занятие!");
                }
            }
        }
    }

    public void removeLesson(int index) {
        if (index >= 0 && index < lessons.size()) lessons.remove(index);
    }
    
    public void removeTeacher(Teacher t) throws Exception {
        for (Lesson l : lessons) {
            if (l.getTeacher().equals(t)) throw new Exception("Нельзя удалить: преподаватель ведет занятия!");
        }
        teachers.remove(t);
    }
    
    public void removeGroup(StudentGroup g) throws Exception {
        for (Lesson l : lessons) {
            if (l.getGroup().equals(g)) throw new Exception("Нельзя удалить: у группы есть занятия!");
        }
        groups.remove(g);
    }
    
    public void removeClassroom(Classroom c) throws Exception {
        for (Lesson l : lessons) {
            if (l.getClassroom().equals(c)) throw new Exception("Нельзя удалить: аудитория занята в расписании!");
        }
        classrooms.remove(c);
    }
    
    public List<Lesson> getLessonsInPeriod(LocalDate start, LocalDate end) {
        return lessons.stream()
                .filter(l -> !l.getDate().isBefore(start) && !l.getDate().isAfter(end))
                .collect(Collectors.toList());
    }
    
    public List<Lesson> getFilteredLessons(String groupName, String dayOfWeek, LocalDate start, LocalDate end) {
        return lessons.stream()
            .filter(l -> (groupName == null || groupName.equals("Все группы") || l.getGroup().getName().equals(groupName)))
            .filter(l -> (dayOfWeek == null || dayOfWeek.equals("Все дни") || l.getTimeSlot().getDay().equals(dayOfWeek)))
            .filter(l -> (start == null || !l.getDate().isBefore(start)))
            .filter(l -> (end == null || !l.getDate().isAfter(end)))
            .collect(Collectors.toList());
    }
    
    public List<Lesson> getSortedLessons(List<Lesson> listToSort) {
        List<Lesson> sorted = new ArrayList<>(listToSort);
        sorted.sort(java.util.Comparator
            .comparing(Lesson::getDate)
            .thenComparing(l -> l.getTimeSlot().getFirstStartTime()) 
        );
        return sorted;
    }
}