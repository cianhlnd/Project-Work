import React from 'react';
import PropTypes from 'prop-types';
import '../../styles/Session.css'; 

function ImageDownload({ imageUrl, imageName, imageSize }) {
  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = imageUrl;
    link.download = imageName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="image-download-container">
      <div className="image-container">
        <img
          src={imageUrl}
          alt={imageName}
          className="image-download"
          style={{ width: imageSize, height: 'auto' }}
        />
        <button className="download-button" onClick={handleDownload}>
          Download {imageName}
        </button>
      </div>
    </div>
  );
}

ImageDownload.propTypes = {
  imageUrl: PropTypes.string.isRequired,
  imageName: PropTypes.string.isRequired,
  imageSize: PropTypes.string.isRequired,
};

export default ImageDownload;