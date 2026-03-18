package unischedule.model;

import java.util.Objects;

public class TimeSlot {
    private final String day;
    private final int lessonNumber; // 1-6 пара

    public TimeSlot(String day, int lessonNumber) {
        this.day = day;
        this.lessonNumber = lessonNumber;
    }

    public String getDay() { return day; }
    public int getLessonNumber() { return lessonNumber; }

    @Override
    public String toString() { return day + ", " + lessonNumber + " пара"; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TimeSlot)) return false;
        TimeSlot timeSlot = (TimeSlot) o;
        return lessonNumber == timeSlot.lessonNumber && Objects.equals(day, timeSlot.day);
    }

    @Override
    public int hashCode() { return Objects.hash(day, lessonNumber); }
}