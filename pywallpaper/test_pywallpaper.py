import unittest
from unittest.mock import patch, MagicMock

from pywallpaper import fetch_wallpaper_url


class TestFetchWallpaperURL(unittest.TestCase):
    @patch("pywallpaper.requests.get")
    def test_fetch_wallpaper_url_success(self, mock_get):
        """Test fetch_wallpaper_url returns correct path when API response is valid."""

        # Mock API response (based on real response you provided)
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [
                {
                    "id": "459px1",
                    "path": "https://w.wallhaven.cc/full/45/wallhaven-459px1.jpg"
                }
            ]
        }
        mock_get.return_value = mock_response

        # Call function
        result = fetch_wallpaper_url()

        # Expected result
        expected_url = "https://w.wallhaven.cc/full/45/wallhaven-459px1.jpg"

        # Assertions
        self.assertEqual(result, expected_url)


if __name__ == "__main__":
    unittest.main()
