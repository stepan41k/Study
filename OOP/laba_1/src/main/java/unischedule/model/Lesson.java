package unischedule.model;

public abstract class Lesson {
    private String subject;
    private Teacher teacher;
    private StudentGroup group;
    private Classroom classroom;
    private TimeSlot timeSlot;

    public Lesson(String subject, Teacher teacher, StudentGroup group, Classroom classroom, TimeSlot timeSlot) {
        this.subject = subject;
        this.teacher = teacher;
        this.group = group;
        this.classroom = classroom;
        this.timeSlot = timeSlot;
    }

    // Геттеры
    public String getSubject() { return subject; }
    public Teacher getTeacher() { return teacher; }
    public StudentGroup getGroup() { return group; }
    public Classroom getClassroom() { return classroom; }
    public TimeSlot getTimeSlot() { return timeSlot; }

    // Полиморфизм: каждый подкласс вернет свой тип
    public abstract String getLessonType();
}