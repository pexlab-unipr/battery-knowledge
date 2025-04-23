function filenames = get_filenames(folder, extension)
    files = dir(fullfile(folder, "*" + extension));
    filenames = strings(size(files));
    for k = 1:length(files)
        filenames(k) = fullfile(folder, files(k).name);
    end
end
