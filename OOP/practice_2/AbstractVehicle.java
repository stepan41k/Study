public abstract class AbstractVehicle implements Vehicle {
    protected String model;
    protected double speed;

    public AbstractVehicle(String model, double speed) {
        this.model = model;
        this.speed = speed;
    }

    @Override
    public double getSpeed() {
        return speed;
    }

    @Override
    public abstract void start();

    @Override
    public abstract void stop();
}