import glob

def count_files(ext,dirct='.'):
    """ Function that returns the number of files in the specified directory
    ending with the specified file extension

    Args:
        ext: File extension string
        dir: Directory to parse (default is current directory)
    Returns:
        int: Number of files
    """

    files = glob.glob(dirct + '/*.' + ext) 
    return len(files)
    
