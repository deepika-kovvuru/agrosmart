export const getWeatherForecast = async (location = 'Guntur, Andhra Pradesh') => {
  return {
    location,
    temperature: 31,
    feels_like: 34,
    condition: 'Partly Cloudy',
    humidity: 72,
    wind_speed: '14 km/h',
    rainfall_chance: '35%',
    uv_index: 'Moderate (6)',
    air_quality: 'Good (42 AQI)',
    advisory: 'Favorable conditions for field scouting and weed control today. Light rain expected by evening.',
    forecast: [
      { day: 'Today', temp: '31°C', condition: 'Partly Cloudy', icon: '⛅', rain: '35%' },
      { day: 'Thu', temp: '29°C', condition: 'Moderate Rain', icon: '🌧️', rain: '80%' },
      { day: 'Fri', temp: '30°C', condition: 'Light Thunderstorm', icon: '🌩️', rain: '65%' },
      { day: 'Sat', temp: '32°C', condition: 'Sunny & Clear', icon: '☀️', rain: '10%' },
      { day: 'Sun', temp: '33°C', condition: 'Mostly Sunny', icon: '🌤️', rain: '15%' },
    ]
  };
};
