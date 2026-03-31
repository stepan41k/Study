package unischedule.model;

import java.util.Objects;

import java.util.List;
import java.util.Objects;
import java.util.Collections;

public class TimeSlot {
    private final String day;
    private final List<String> startTimes;

    public TimeSlot(String day, List<String> startTimes) {
        this.day = day;
        Collections.sort(startTimes);
        this.startTimes = startTimes;
    }

    public String getDay() { return day; }
    public List<String> getStartTimes() { return startTimes; }

    public String getFormattedRange() {
        if (startTimes == null || startTimes.isEmpty()) return "";
        String first = startTimes.get(0);
        String last = startTimes.get(startTimes.size() - 1);
        
        int lastHour = Integer.parseInt(last.split(":")[0]) + 1;
        String endTime = String.format("%02d:00", lastHour);
        
        return first + " - " + endTime;
    }

    @Override
    public String toString() { return getFormattedRange(); }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TimeSlot)) return false;
        TimeSlot timeSlot = (TimeSlot) o;
        return Objects.equals(day, timeSlot.day) && Objects.equals(startTimes, timeSlot.startTimes);
    }

    @Override
    public int hashCode() { return Objects.hash(day, startTimes); }
    
    public String getFirstStartTime() {
        return (startTimes != null && !startTimes.isEmpty()) ? startTimes.get(0) : "00:00";
    }
}